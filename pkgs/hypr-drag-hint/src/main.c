#define _GNU_SOURCE

#include <cairo/cairo.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/inotify.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>

#include "wlr-layer-shell-unstable-v1-client-protocol.h"

#define MAX_OUTPUTS 16
#define MAX_TILES 64
#define MAX_SHADE_MAP 128
#define POLL_INTERVAL_MS 16
#define SCENE_FILENAME "hypr-drag-hint.scene"

enum split_side {
    SPLIT_NONE = 0,
    SPLIT_LEFT,
    SPLIT_RIGHT,
    SPLIT_TOP,
    SPLIT_BOTTOM,
};

enum overlay_phase {
    PHASE_IDLE = 0,
    PHASE_ACTIVE,
    PHASE_HIDING,
};

struct rect_f {
    double x, y, w, h;
};

struct rgb_color {
    double r, g, b;
};

struct wl_output_info {
    uint32_t global_name;
    struct wl_output *output;
    char name[64];
    int32_t scale;
    bool active;
};

struct shm_buffer {
    struct wl_buffer *wl_buf;
    void *data;
    size_t size;
    int width;
    int height;
    bool busy;
};

struct overlay_surface {
    struct wl_output_info *output;
    struct wl_surface *surface;
    struct zwlr_layer_surface_v1 *layer_surface;
    int width;
    int height;
    int scale;
    bool configured;
    struct shm_buffer bufs[2];
    int cur_buf;
};

struct shade_entry {
    char key[32];
    int slot;
};

struct anim_tile {
    char key[32];
    bool active;
    bool seen;
    bool is_dragged;
    bool is_split_partner;
    bool is_root_edge;
    bool is_swap_zone;
    enum split_side split_side;
    struct rgb_color color;
    struct rect_f cur;
    struct rect_f tgt;
    double alpha;
    double scale;
};

struct app_state {
    /* Visual config */
    double accent_r, accent_g, accent_b;
    double fill_alpha;
    double border_alpha;
    double rounding;

    /* Control paths */
    char runtime_dir[256];
    char scene_path[512];
    int inotify_fd;
    int inotify_wd;

    /* Wayland globals */
    struct wl_display *display;
    struct wl_registry *registry;
    struct wl_compositor *compositor;
    struct wl_shm *shm;
    struct zwlr_layer_shell_v1 *layer_shell;
    struct wl_output_info outputs[MAX_OUTPUTS];
    struct overlay_surface overlay;

    /* Animation state */
    enum overlay_phase phase;
    int64_t last_tick_ms;
    char preview_monitor[64];
    double master_alpha;
    double master_scale;
    bool show_ghost;
    double ghost_x, ghost_y, ghost_w, ghost_h;
    struct anim_tile tiles[MAX_TILES];
    struct shade_entry shade_map[MAX_SHADE_MAP];
    int shade_count;
};

static volatile sig_atomic_t g_running = 1;

static void handle_signal(int sig) {
    (void)sig;
    g_running = 0;
}

static int64_t now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static bool parse_hex_color(const char *hex, double *r, double *g, double *b) {
    if (!hex) return false;
    if (hex[0] == '#') hex++;
    if (strlen(hex) < 6) return false;
    char buf[3] = {0};
    buf[0] = hex[0]; buf[1] = hex[1];
    *r = (double)strtoul(buf, NULL, 16) / 255.0;
    buf[0] = hex[2]; buf[1] = hex[3];
    *g = (double)strtoul(buf, NULL, 16) / 255.0;
    buf[0] = hex[4]; buf[1] = hex[5];
    *b = (double)strtoul(buf, NULL, 16) / 255.0;
    return true;
}

static enum split_side parse_side(const char *s) {
    if (!s) return SPLIT_NONE;
    if (strcmp(s, "left") == 0) return SPLIT_LEFT;
    if (strcmp(s, "right") == 0) return SPLIT_RIGHT;
    if (strcmp(s, "top") == 0) return SPLIT_TOP;
    if (strcmp(s, "bottom") == 0) return SPLIT_BOTTOM;
    return SPLIT_NONE;
}

/* ── HSL Color Shade Generation ───────────────────────────────────────────── */

static void rgb_to_hsl(double r, double g, double b, double *h, double *s, double *l) {
    double max = fmax(r, fmax(g, b));
    double min = fmin(r, fmin(g, b));
    double d = max - min;
    *l = (max + min) * 0.5;
    if (d < 1e-6) {
        *h = 0.0;
        *s = 0.0;
        return;
    }
    *s = (*l > 0.5) ? d / (2.0 - max - min) : d / (max + min);
    if (max == r)
        *h = fmod((g - b) / d + (g < b ? 6.0 : 0.0), 6.0) / 6.0;
    else if (max == g)
        *h = ((b - r) / d + 2.0) / 6.0;
    else
        *h = ((r - g) / d + 4.0) / 6.0;
}

static double hue_to_rgb(double p, double q, double t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0 / 2.0) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

static struct rgb_color hsl_to_rgb(double h, double s, double l) {
    struct rgb_color out;
    if (s < 1e-6) {
        out.r = out.g = out.b = l;
        return out;
    }
    double q = (l < 0.5) ? l * (1.0 + s) : l + s - l * s;
    double p = 2.0 * l - q;
    out.r = hue_to_rgb(p, q, h + 1.0 / 3.0);
    out.g = hue_to_rgb(p, q, h);
    out.b = hue_to_rgb(p, q, h - 1.0 / 3.0);
    return out;
}

static struct rgb_color shade_for_key(struct app_state *app, const char *key) {
    int slot = -1;
    for (int i = 0; i < app->shade_count; i++) {
        if (strcmp(app->shade_map[i].key, key) == 0) {
            slot = app->shade_map[i].slot;
            break;
        }
    }
    if (slot < 0) {
        slot = app->shade_count;
        if (app->shade_count < MAX_SHADE_MAP) {
            snprintf(app->shade_map[app->shade_count].key,
                     sizeof(app->shade_map[app->shade_count].key), "%s", key);
            app->shade_map[app->shade_count].slot = slot;
            app->shade_count++;
        }
    }

    static const double hue_offsets_deg[] = {
        -45.0, -95.0, +42.0, +105.0, -145.0, +155.0, -22.0, +72.0,
    };
    const int n_offsets = (int)(sizeof(hue_offsets_deg) / sizeof(hue_offsets_deg[0]));

    double h, s, l;
    rgb_to_hsl(app->accent_r, app->accent_g, app->accent_b, &h, &s, &l);
    if (s < 0.35) s = 0.65;
    if (l < 0.50) l = 0.68;
    if (l > 0.85) l = 0.78;

    double deg = hue_offsets_deg[slot % n_offsets];
    double l_shift = ((slot / n_offsets) % 2) ? -0.08 : 0.0;
    double nh = fmod(h + deg / 360.0 + 1.0, 1.0);
    double nl = fmax(0.45, fmin(0.85, l + l_shift));
    return hsl_to_rgb(nh, s * 0.90, nl);
}

/* ── Wayland SHM & Layer Surface ──────────────────────────────────────────── */

static void shm_buffer_release(void *data, struct wl_buffer *wl_buf) {
    (void)wl_buf;
    ((struct shm_buffer *)data)->busy = false;
}

static const struct wl_buffer_listener shm_buffer_listener = {
    .release = shm_buffer_release,
};

static void shm_buffer_destroy(struct shm_buffer *buf) {
    if (buf->wl_buf) {
        wl_buffer_destroy(buf->wl_buf);
        buf->wl_buf = NULL;
    }
    if (buf->data && buf->data != MAP_FAILED) {
        munmap(buf->data, buf->size);
        buf->data = NULL;
    }
    buf->size = 0;
    buf->width = 0;
    buf->height = 0;
    buf->busy = false;
}

static bool shm_buffer_ensure(struct wl_shm *shm, struct shm_buffer *buf, int w, int h) {
    if (buf->wl_buf && buf->width == w && buf->height == h)
        return true;

    shm_buffer_destroy(buf);
    int stride = w * 4;
    size_t size = (size_t)stride * (size_t)h;
    int fd = memfd_create("hypr-drag-hint", MFD_CLOEXEC);
    if (fd < 0) return false;
    if (ftruncate(fd, (off_t)size) < 0) { close(fd); return false; }

    void *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) { close(fd); return false; }

    struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, (int32_t)size);
    buf->wl_buf = wl_shm_pool_create_buffer(pool, 0, w, h, stride, WL_SHM_FORMAT_ARGB8888);
    wl_shm_pool_destroy(pool);
    close(fd);

    if (!buf->wl_buf) { munmap(data, size); return false; }
    wl_buffer_add_listener(buf->wl_buf, &shm_buffer_listener, buf);
    buf->data = data;
    buf->size = size;
    buf->width = w;
    buf->height = h;
    buf->busy = false;
    return true;
}

static void overlay_destroy(struct app_state *app) {
    struct overlay_surface *ov = &app->overlay;
    if (ov->layer_surface) {
        zwlr_layer_surface_v1_destroy(ov->layer_surface);
        ov->layer_surface = NULL;
    }
    if (ov->surface) {
        wl_surface_destroy(ov->surface);
        ov->surface = NULL;
    }
    shm_buffer_destroy(&ov->bufs[0]);
    shm_buffer_destroy(&ov->bufs[1]);
    ov->output = NULL;
    ov->configured = false;
    ov->width = 0;
    ov->height = 0;
    if (app->display)
        wl_display_flush(app->display);
}

static void layer_surface_configure(void *data, struct zwlr_layer_surface_v1 *ls,
                                    uint32_t serial, uint32_t width, uint32_t height) {
    struct app_state *app = data;
    zwlr_layer_surface_v1_ack_configure(ls, serial);
    app->overlay.width = (int)width;
    app->overlay.height = (int)height;
    app->overlay.configured = (width > 0 && height > 0);
}

static void layer_surface_closed(void *data, struct zwlr_layer_surface_v1 *ls) {
    (void)ls;
    overlay_destroy((struct app_state *)data);
}

static const struct zwlr_layer_surface_v1_listener layer_surface_listener = {
    .configure = layer_surface_configure,
    .closed = layer_surface_closed,
};

static struct wl_output_info *find_wl_output(struct app_state *app, const char *name) {
    for (int i = 0; i < MAX_OUTPUTS; i++) {
        if (app->outputs[i].active && strcmp(app->outputs[i].name, name) == 0)
            return &app->outputs[i];
    }
    return NULL;
}

static bool overlay_ensure_on_output(struct app_state *app, const char *mon_name) {
    struct wl_output_info *out = find_wl_output(app, mon_name);
    if (!out || !app->compositor || !app->layer_shell)
        return false;
    if (app->overlay.layer_surface && app->overlay.output == out)
        return app->overlay.configured;

    overlay_destroy(app);

    struct overlay_surface *ov = &app->overlay;
    ov->output = out;
    ov->scale = out->scale > 0 ? out->scale : 1;
    ov->surface = wl_compositor_create_surface(app->compositor);
    if (!ov->surface) return false;

    struct wl_region *empty = wl_compositor_create_region(app->compositor);
    wl_surface_set_input_region(ov->surface, empty);
    wl_region_destroy(empty);

    ov->layer_surface = zwlr_layer_shell_v1_get_layer_surface(
        app->layer_shell, ov->surface, out->output,
        ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, "hypr-drag-hint");
    if (!ov->layer_surface) {
        overlay_destroy(app);
        return false;
    }

    zwlr_layer_surface_v1_set_anchor(
        ov->layer_surface,
        ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP |
        ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM |
        ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT |
        ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT);
    zwlr_layer_surface_v1_set_exclusive_zone(ov->layer_surface, -1);
    zwlr_layer_surface_v1_set_keyboard_interactivity(
        ov->layer_surface, ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_NONE);
    zwlr_layer_surface_v1_set_size(ov->layer_surface, 0, 0);
    zwlr_layer_surface_v1_add_listener(ov->layer_surface, &layer_surface_listener, app);

    wl_surface_commit(ov->surface);
    wl_display_roundtrip(app->display);
    return ov->configured;
}

/* ── Cairo Rendering ──────────────────────────────────────────────────────── */

static void cairo_rounded_rect(cairo_t *cr, double x, double y, double w, double h, double r) {
    if (r > w / 2.0) r = w / 2.0;
    if (r > h / 2.0) r = h / 2.0;
    if (r < 0.0) r = 0.0;

    cairo_new_sub_path(cr);
    cairo_arc(cr, x + w - r, y + r, r, -M_PI / 2.0, 0);
    cairo_arc(cr, x + w - r, y + h - r, r, 0, M_PI / 2.0);
    cairo_arc(cr, x + r, y + h - r, r, M_PI / 2.0, M_PI);
    cairo_arc(cr, x + r, y + r, r, M_PI, 3.0 * M_PI / 2.0);
    cairo_close_path(cr);
}

static void draw_tile(cairo_t *cr, const struct app_state *app, const struct anim_tile *t) {
    double a = t->alpha * app->master_alpha;
    if (a <= 0.005 || t->cur.w <= 4.0 || t->cur.h <= 4.0)
        return;

    double sc = t->scale * app->master_scale;
    double cx = t->cur.x + t->cur.w * 0.5;
    double cy = t->cur.y + t->cur.h * 0.5;
    double sw = t->cur.w * sc;
    double sh = t->cur.h * sc;

    double inset = 2.0;
    double rx = cx - sw * 0.5 + inset;
    double ry = cy - sh * 0.5 + inset;
    double rw = sw - inset * 2.0;
    double rh = sh - inset * 2.0;
    if (rw <= 2.0 || rh <= 2.0) return;

    double rad = app->rounding;
    double fill_a, border_a, border_w;
    if (t->is_dragged) {
        fill_a = app->fill_alpha * (t->is_root_edge ? 1.45 : 1.25) * a;
        border_a = app->border_alpha * a;
        border_w = t->is_root_edge ? 3.0 : 2.5;
    } else if (t->is_split_partner) {
        fill_a = app->fill_alpha * 0.85 * a;
        border_a = app->border_alpha * 0.72 * a;
        border_w = 2.0;
    } else {
        fill_a = app->fill_alpha * 0.65 * a;
        border_a = app->border_alpha * 0.52 * a;
        border_w = 1.5;
    }

    cairo_rounded_rect(cr, rx, ry, rw, rh, rad);
    cairo_set_source_rgba(cr, t->color.r, t->color.g, t->color.b, fill_a);
    cairo_fill_preserve(cr);

    cairo_set_source_rgba(cr, t->color.r, t->color.g, t->color.b, border_a);
    cairo_set_line_width(cr, border_w);
    cairo_stroke(cr);

    if (t->is_dragged && rw > 12.0 && rh > 12.0) {
        cairo_rounded_rect(cr, rx + 2.0, ry + 2.0, rw - 4.0, rh - 4.0, rad > 2.0 ? rad - 2.0 : 0.0);
        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.16 * a);
        cairo_set_line_width(cr, 1.0);
        cairo_stroke(cr);

        if (t->is_swap_zone) {
            double gx = rx + rw * 0.5;
            double gy = ry + rh * 0.5;
            double r = 11.0;
            cairo_set_source_rgba(cr, t->color.r, t->color.g, t->color.b, 0.92 * a);
            cairo_set_line_width(cr, 2.4);
            cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
            cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
            if (t->split_side == SPLIT_TOP || t->split_side == SPLIT_BOTTOM) {
                cairo_move_to(cr, gx - r * 0.6, gy - r * 0.35);
                cairo_line_to(cr, gx, gy - r * 0.95);
                cairo_line_to(cr, gx + r * 0.6, gy - r * 0.35);
                cairo_move_to(cr, gx - r * 0.6, gy + r * 0.35);
                cairo_line_to(cr, gx, gy + r * 0.95);
                cairo_line_to(cr, gx + r * 0.6, gy + r * 0.35);
            } else {
                cairo_move_to(cr, gx - r * 0.35, gy - r * 0.6);
                cairo_line_to(cr, gx - r * 0.95, gy);
                cairo_line_to(cr, gx - r * 0.35, gy + r * 0.6);
                cairo_move_to(cr, gx + r * 0.35, gy - r * 0.6);
                cairo_line_to(cr, gx + r * 0.95, gy);
                cairo_line_to(cr, gx + r * 0.35, gy + r * 0.6);
            }
            cairo_stroke(cr);
        } else if (t->split_side != SPLIT_NONE) {
            double pill_t = t->is_root_edge ? 5.0 : 4.0;
            double pad = 8.0;
            double frac = t->is_root_edge ? 0.42 : 0.24;
            double max_len = t->is_root_edge ? 260.0 : 120.0;
            double px = 0, py = 0, pw = 0, ph = 0;

            if (t->split_side == SPLIT_LEFT || t->split_side == SPLIT_RIGHT) {
                ph = rh * frac;
                if (ph < 28.0) ph = fmin(28.0, rh - 16.0);
                if (ph > max_len) ph = max_len;
                pw = pill_t;
                py = ry + (rh - ph) * 0.5;
                px = (t->split_side == SPLIT_LEFT) ? (rx + pad) : (rx + rw - pad - pw);
            } else {
                pw = rw * frac;
                if (pw < 28.0) pw = fmin(28.0, rw - 16.0);
                if (pw > max_len) pw = max_len;
                ph = pill_t;
                px = rx + (rw - pw) * 0.5;
                py = (t->split_side == SPLIT_TOP) ? (ry + pad) : (ry + rh - pad - ph);
            }

            if (pw > 0.0 && ph > 0.0) {
                cairo_rounded_rect(cr, px, py, pw, ph, pill_t * 0.5);
                cairo_set_source_rgba(cr, t->color.r, t->color.g, t->color.b, 0.95 * a);
                cairo_fill(cr);
            }
        }
    }
}

static void draw_ghost_card(cairo_t *cr, const struct app_state *app) {
    if (!app->show_ghost || app->master_alpha <= 0.01)
        return;

    double a = app->master_alpha;
    double gx = app->ghost_x - app->ghost_w * 0.5;
    double gy = app->ghost_y - app->ghost_h * 0.5;

    cairo_rounded_rect(cr, gx, gy, app->ghost_w, app->ghost_h, 6.0);
    cairo_set_source_rgba(cr, app->accent_r, app->accent_g, app->accent_b, 0.24 * a);
    cairo_fill_preserve(cr);

    cairo_set_source_rgba(cr, app->accent_r, app->accent_g, app->accent_b, 0.92 * a);
    cairo_set_line_width(cr, 1.8);
    cairo_stroke(cr);
}

static void overlay_render(struct app_state *app) {
    struct overlay_surface *ov = &app->overlay;
    if (!ov->configured || !ov->surface || ov->width <= 0 || ov->height <= 0)
        return;

    int buf_idx = ov->cur_buf;
    if (ov->bufs[buf_idx].busy) buf_idx = 1 - buf_idx;
    if (ov->bufs[buf_idx].busy) return;

    int scale = ov->scale > 0 ? ov->scale : 1;
    int px_w = ov->width * scale;
    int px_h = ov->height * scale;

    struct shm_buffer *buf = &ov->bufs[buf_idx];
    if (!shm_buffer_ensure(app->shm, buf, px_w, px_h))
        return;

    cairo_surface_t *cs = cairo_image_surface_create_for_data(
        buf->data, CAIRO_FORMAT_ARGB32, px_w, px_h, px_w * 4);
    cairo_t *cr = cairo_create(cs);
    cairo_scale(cr, (double)scale, (double)scale);

    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    for (int i = 0; i < MAX_TILES; i++) {
        if (app->tiles[i].active && !app->tiles[i].is_dragged)
            draw_tile(cr, app, &app->tiles[i]);
    }
    for (int i = 0; i < MAX_TILES; i++) {
        if (app->tiles[i].active && app->tiles[i].is_dragged)
            draw_tile(cr, app, &app->tiles[i]);
    }
    draw_ghost_card(cr, app);

    cairo_destroy(cr);
    cairo_surface_destroy(cs);

    buf->busy = true;
    ov->cur_buf = 1 - buf_idx;
    wl_surface_set_buffer_scale(ov->surface, scale);
    wl_surface_attach(ov->surface, buf->wl_buf, 0, 0);
    wl_surface_damage_buffer(ov->surface, 0, 0, px_w, px_h);
    wl_surface_commit(ov->surface);
    wl_display_flush(app->display);
}

/* ── Wayland Registry & Output Listeners ──────────────────────────────────── */

static void output_geometry(void *d, struct wl_output *o, int32_t x, int32_t y,
                            int32_t pw, int32_t ph, int32_t sp, const char *mk,
                            const char *md, int32_t tf) {
    (void)d; (void)o; (void)x; (void)y; (void)pw; (void)ph;
    (void)sp; (void)mk; (void)md; (void)tf;
}
static void output_mode(void *d, struct wl_output *o, uint32_t f, int32_t w, int32_t h, int32_t r) {
    (void)d; (void)o; (void)f; (void)w; (void)h; (void)r;
}
static void output_done(void *d, struct wl_output *o) { (void)d; (void)o; }
static void output_scale(void *data, struct wl_output *o, int32_t factor) {
    (void)o;
    ((struct wl_output_info *)data)->scale = factor > 0 ? factor : 1;
}
static void output_name(void *data, struct wl_output *o, const char *name) {
    (void)o;
    struct wl_output_info *info = data;
    snprintf(info->name, sizeof(info->name), "%s", name ? name : "");
}
static void output_description(void *d, struct wl_output *o, const char *desc) {
    (void)d; (void)o; (void)desc;
}

static const struct wl_output_listener output_listener = {
    .geometry = output_geometry,
    .mode = output_mode,
    .done = output_done,
    .scale = output_scale,
    .name = output_name,
    .description = output_description,
};

static void registry_global(void *data, struct wl_registry *reg, uint32_t name,
                            const char *interface, uint32_t version) {
    struct app_state *app = data;
    if (strcmp(interface, wl_compositor_interface.name) == 0) {
        app->compositor = wl_registry_bind(reg, name, &wl_compositor_interface,
                                           version < 4 ? version : 4);
    } else if (strcmp(interface, wl_shm_interface.name) == 0) {
        app->shm = wl_registry_bind(reg, name, &wl_shm_interface, 1);
    } else if (strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
        app->layer_shell = wl_registry_bind(reg, name, &zwlr_layer_shell_v1_interface, 1);
    } else if (strcmp(interface, wl_output_interface.name) == 0) {
        for (int i = 0; i < MAX_OUTPUTS; i++) {
            if (!app->outputs[i].active) {
                app->outputs[i].active = true;
                app->outputs[i].global_name = name;
                app->outputs[i].scale = 1;
                app->outputs[i].name[0] = '\0';
                uint32_t bind_ver = version < 4 ? version : 4;
                app->outputs[i].output = wl_registry_bind(reg, name, &wl_output_interface, bind_ver);
                wl_output_add_listener(app->outputs[i].output, &output_listener, &app->outputs[i]);
                break;
            }
        }
    }
}

static void registry_global_remove(void *data, struct wl_registry *reg, uint32_t name) {
    (void)reg;
    struct app_state *app = data;
    for (int i = 0; i < MAX_OUTPUTS; i++) {
        if (app->outputs[i].active && app->outputs[i].global_name == name) {
            if (app->overlay.output == &app->outputs[i])
                overlay_destroy(app);
            wl_output_destroy(app->outputs[i].output);
            app->outputs[i].output = NULL;
            app->outputs[i].active = false;
            break;
        }
    }
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

/* ── Scene Parsing & Animation ────────────────────────────────────────────── */

static void finish_hide(struct app_state *app) {
    app->phase = PHASE_IDLE;
    app->show_ghost = false;
    app->preview_monitor[0] = '\0';
    app->master_alpha = 0.0;
    app->master_scale = 0.97;
    app->shade_count = 0;
    memset(app->tiles, 0, sizeof(app->tiles));
    overlay_destroy(app);
}

static void begin_hiding(struct app_state *app) {
    app->show_ghost = false;
    if (app->phase == PHASE_IDLE || !app->overlay.configured || app->master_alpha <= 0.02) {
        finish_hide(app);
        return;
    }
    app->phase = PHASE_HIDING;
    app->last_tick_ms = now_ms();
}

static void upsert_tile(struct app_state *app, const char *key,
                        struct rect_f tgt, bool is_dragged, bool is_partner,
                        bool is_root, bool is_swap, enum split_side side) {
    struct rgb_color col = is_dragged
        ? (struct rgb_color){ app->accent_r, app->accent_g, app->accent_b }
        : shade_for_key(app, key);

    struct anim_tile *found = NULL;
    struct anim_tile *free_slot = NULL;
    for (int i = 0; i < MAX_TILES; i++) {
        if (app->tiles[i].active && strcmp(app->tiles[i].key, key) == 0) {
            found = &app->tiles[i];
            break;
        }
        if (!app->tiles[i].active && !free_slot)
            free_slot = &app->tiles[i];
    }

    if (found) {
        found->seen = true;
        found->tgt = tgt;
        found->color = col;
        found->is_dragged = is_dragged;
        found->is_split_partner = is_partner;
        found->is_root_edge = is_root;
        found->is_swap_zone = is_swap;
        found->split_side = side;
        return;
    }

    if (!free_slot) return;
    memset(free_slot, 0, sizeof(*free_slot));
    snprintf(free_slot->key, sizeof(free_slot->key), "%s", key);
    free_slot->active = true;
    free_slot->seen = true;
    free_slot->is_dragged = is_dragged;
    free_slot->is_split_partner = is_partner;
    free_slot->is_root_edge = is_root;
    free_slot->is_swap_zone = is_swap;
    free_slot->split_side = side;
    free_slot->color = col;
    free_slot->cur = tgt;
    free_slot->tgt = tgt;
    free_slot->alpha = 0.0;
    free_slot->scale = 0.965;
}

static void load_scene_file(struct app_state *app) {
    FILE *f = fopen(app->scene_path, "r");
    if (!f) return;

    char line[256];
    if (!fgets(line, sizeof(line), f)) {
        fclose(f);
        return;
    }

    if (strncmp(line, "hide", 4) == 0) {
        fclose(f);
        begin_hiding(app);
        return;
    }

    char mon[64] = {0};
    double gx = 0, gy = 0, gw = 0, gh = 0;
    if (sscanf(line, "scene %63s %lf %lf %lf %lf", mon, &gx, &gy, &gw, &gh) < 1) {
        fclose(f);
        return;
    }

    bool fresh_start = (app->phase != PHASE_ACTIVE);
    bool mon_changed = (strcmp(app->preview_monitor, mon) != 0);

    if (fresh_start || mon_changed) {
        snprintf(app->preview_monitor, sizeof(app->preview_monitor), "%s", mon);
        memset(app->tiles, 0, sizeof(app->tiles));
        if (fresh_start)
            app->shade_count = 0;
        app->master_alpha = 0.0;
        app->master_scale = 0.97;
        app->last_tick_ms = now_ms();
    }

    app->phase = PHASE_ACTIVE;
    app->show_ghost = (gw > 1.0 && gh > 1.0);
    app->ghost_x = gx;
    app->ghost_y = gy;
    app->ghost_w = gw;
    app->ghost_h = gh;

    for (int i = 0; i < MAX_TILES; i++)
        app->tiles[i].seen = false;

    while (fgets(line, sizeof(line), f)) {
        char key[32] = {0}, side_s[16] = {0};
        double x, y, w, h;
        int is_d = 0, is_p = 0, is_r = 0, is_s = 0;
        if (sscanf(line, "tile %31s %lf %lf %lf %lf %d %d %d %d %15s",
                   key, &x, &y, &w, &h, &is_d, &is_p, &is_r, &is_s, side_s) >= 9) {
            struct rect_f r = { x, y, w, h };
            upsert_tile(app, key, r, is_d != 0, is_p != 0, is_r != 0, is_s != 0, parse_side(side_s));
        }
    }
    fclose(f);

    overlay_ensure_on_output(app, mon);
}

static void tick_animations(struct app_state *app) {
    if (app->phase == PHASE_IDLE)
        return;

    int64_t t_now = now_ms();
    double dt = (double)(t_now - app->last_tick_ms) / 1000.0;
    app->last_tick_ms = t_now;
    if (dt < 0.001) dt = 0.016;
    if (dt > 0.1) dt = 0.1;

    double pos_k = 1.0 - exp(-dt * 18.0);
    double fade_in_k = 1.0 - exp(-dt * 15.0);
    double fade_out_k = 1.0 - exp(-dt * 18.0);

    if (app->phase == PHASE_ACTIVE) {
        app->master_alpha += (1.0 - app->master_alpha) * fade_in_k;
        if (app->master_alpha > 0.995) app->master_alpha = 1.0;
        app->master_scale += (1.0 - app->master_scale) * fade_in_k;
        if (fabs(1.0 - app->master_scale) < 0.001) app->master_scale = 1.0;
    } else if (app->phase == PHASE_HIDING) {
        app->master_alpha += (0.0 - app->master_alpha) * fade_out_k;
        app->master_scale += (0.97 - app->master_scale) * fade_out_k;
        if (app->master_alpha <= 0.012) {
            finish_hide(app);
            return;
        }
    }

    for (int i = 0; i < MAX_TILES; i++) {
        struct anim_tile *t = &app->tiles[i];
        if (!t->active) continue;

        t->cur.x += (t->tgt.x - t->cur.x) * pos_k;
        t->cur.y += (t->tgt.y - t->cur.y) * pos_k;
        t->cur.w += (t->tgt.w - t->cur.w) * pos_k;
        t->cur.h += (t->tgt.h - t->cur.h) * pos_k;

        if (app->phase == PHASE_ACTIVE && t->seen) {
            t->alpha += (1.0 - t->alpha) * fade_in_k;
            if (t->alpha > 0.995) t->alpha = 1.0;
            t->scale += (1.0 - t->scale) * fade_in_k;
            if (fabs(1.0 - t->scale) < 0.001) t->scale = 1.0;
        } else if (app->phase == PHASE_ACTIVE && !t->seen) {
            t->alpha += (0.0 - t->alpha) * fade_out_k;
            t->scale += (0.965 - t->scale) * fade_out_k;
            if (t->alpha < 0.01) t->active = false;
        }
    }

    overlay_render(app);
}

static void read_inotify(struct app_state *app) {
    char buf[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
    bool updated = false;
    for (;;) {
        ssize_t n = read(app->inotify_fd, buf, sizeof(buf));
        if (n <= 0) break;
        for (char *p = buf; p < buf + n; ) {
            const struct inotify_event *ev = (const struct inotify_event *)p;
            if (ev->len > 0 && strcmp(ev->name, SCENE_FILENAME) == 0)
                updated = true;
            p += sizeof(struct inotify_event) + ev->len;
        }
    }
    if (updated) {
        load_scene_file(app);
        tick_animations(app);
    }
}

int main(int argc, char **argv) {
    struct app_state app;
    memset(&app, 0, sizeof(app));
    app.inotify_fd = -1;
    app.inotify_wd = -1;
    app.phase = PHASE_IDLE;
    app.accent_r = 0.776;
    app.accent_g = 0.627;
    app.accent_b = 0.965;
    app.fill_alpha = 0.16;
    app.border_alpha = 0.85;
    app.rounding = 8.0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--color") == 0 && i + 1 < argc) {
            parse_hex_color(argv[++i], &app.accent_r, &app.accent_g, &app.accent_b);
        } else if (strcmp(argv[i], "--fill-alpha") == 0 && i + 1 < argc) {
            app.fill_alpha = atof(argv[++i]);
        } else if (strcmp(argv[i], "--border-alpha") == 0 && i + 1 < argc) {
            app.border_alpha = atof(argv[++i]);
        } else if (strcmp(argv[i], "--rounding") == 0 && i + 1 < argc) {
            app.rounding = atof(argv[++i]);
        }
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);
    signal(SIGPIPE, SIG_IGN);

    const char *rt = getenv("XDG_RUNTIME_DIR");
    if (!rt || !rt[0]) rt = "/tmp";
    snprintf(app.runtime_dir, sizeof(app.runtime_dir), "%s", rt);
    snprintf(app.scene_path, sizeof(app.scene_path), "%s/%s", rt, SCENE_FILENAME);

    app.inotify_fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (app.inotify_fd < 0) {
        perror("inotify_init1");
        return 1;
    }
    app.inotify_wd = inotify_add_watch(app.inotify_fd, app.runtime_dir,
                                       IN_CLOSE_WRITE | IN_MOVED_TO);

    app.display = wl_display_connect(NULL);
    if (!app.display) {
        fprintf(stderr, "hypr-drag-hint: failed to connect to Wayland display\n");
        return 1;
    }

    app.registry = wl_display_get_registry(app.display);
    wl_registry_add_listener(app.registry, &registry_listener, &app);
    wl_display_roundtrip(app.display);
    wl_display_roundtrip(app.display);

    if (!app.compositor || !app.shm || !app.layer_shell) {
        fprintf(stderr, "hypr-drag-hint: compositor missing wlr-layer-shell\n");
        return 1;
    }

    int wl_fd = wl_display_get_fd(app.display);

    while (g_running) {
        while (wl_display_prepare_read(app.display) != 0)
            wl_display_dispatch_pending(app.display);
        wl_display_flush(app.display);

        struct pollfd fds[2];
        fds[0].fd = wl_fd;
        fds[0].events = POLLIN;
        fds[1].fd = app.inotify_fd;
        fds[1].events = POLLIN;

        int timeout = (app.phase != PHASE_IDLE) ? POLL_INTERVAL_MS : -1;
        int ret = poll(fds, 2, timeout);

        if (ret < 0) {
            wl_display_cancel_read(app.display);
            if (errno == EINTR) continue;
            break;
        }

        if (fds[0].revents & POLLIN) {
            if (wl_display_read_events(app.display) < 0) break;
            wl_display_dispatch_pending(app.display);
        } else {
            wl_display_cancel_read(app.display);
        }

        if (fds[0].revents & (POLLERR | POLLHUP))
            break;

        if (fds[1].revents & POLLIN)
            read_inotify(&app);

        if (app.phase != PHASE_IDLE)
            tick_animations(&app);
    }

    overlay_destroy(&app);
    close(app.inotify_fd);
    for (int i = 0; i < MAX_OUTPUTS; i++) {
        if (app.outputs[i].active)
            wl_output_destroy(app.outputs[i].output);
    }
    if (app.layer_shell) zwlr_layer_shell_v1_destroy(app.layer_shell);
    if (app.shm) wl_shm_destroy(app.shm);
    if (app.compositor) wl_compositor_destroy(app.compositor);
    if (app.registry) wl_registry_destroy(app.registry);
    wl_display_disconnect(app.display);
    return 0;
}
