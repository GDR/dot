-- Native Hyprland 0.57+ Binary Space Partitioning (BSP) Layout Provider
-- Owns the exact binary tree per workspace so drag previews, swaps, splits,
-- and root-edge docking are 100% consistent with zero background reflow during drag.

local M = {}

local ROOT_EDGE_PX = 130
local CENTER_MARGIN = 0.25 -- inner 50% (0.25..0.75) triggers in-place swap
local MIN_RATIO = 0.12
local MAX_RATIO = 0.88

-- Per-workspace binary trees and cached work areas:
--   Node = { kind = "leaf", addr = "0x..." }
--        | { kind = "split", dir = "h"|"v", ratio = 0.5, first = Node, second = Node }
local trees = {}
local ws_areas = {}       -- ws_id -> { x, y, w, h }
local pending_ops = {}    -- addr -> { ws_id, kind, target_addr, side }

-- Active drag & resize states
local drag_state = nil
local resize_state = nil
local drag_timer = nil
local resize_timer = nil

local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local scene_path = runtime_dir .. "/hypr-drag-hint.scene"
local scene_tmp_path = runtime_dir .. "/hypr-drag-hint.scene.tmp"

------------------------------------------------------------
-- Utility helpers
------------------------------------------------------------

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function norm_addr(a)
    if not a then return "" end
    local s = tostring(a)
    if s:sub(1, 2) == "0x" or s:sub(1, 2) == "0X" then
        return s:sub(3)
    end
    return s
end

local function full_addr(a)
    local n = norm_addr(a)
    if n == "" then return "" end
    return "0x" .. n
end

local function box_xywh(at, sz)
    if not at or not sz then return nil end
    local x = at[1] or at.x
    local y = at[2] or at.y
    local w = sz[1] or sz.x
    local h = sz[2] or sz.y
    if not (x and y and w and h) then return nil end
    return { x = x, y = y, w = w, h = h }
end

local function mon_logical_rect(mon)
    if not mon then return nil end
    local scale = (mon.scale and mon.scale > 0) and mon.scale or 1
    local tf = mon.transform or 0
    local w, h = mon.width or 0, mon.height or 0
    if (tf % 2) == 1 then
        w, h = h, w
    end
    return { x = mon.x or 0, y = mon.y or 0, w = w / scale, h = h / scale }
end

local function mon_work_area(mon, ws_id)
    if ws_id and ws_areas[ws_id] then
        return ws_areas[ws_id]
    end
    local mr = mon_logical_rect(mon)
    if not mr then return { x = 0, y = 0, w = 1920, h = 1080 } end
    local r = mon.reserved or { 0, 0, 0, 0 }
    local rl = r[1] or 0
    local rt = r[2] or 0
    local rr = r[3] or 0
    local rb = r[4] or 0
    return {
        x = mr.x + rl,
        y = mr.y + rt,
        w = mr.w - rl - rr,
        h = mr.h - rt - rb,
    }
end

local function write_scene(content)
    -- Atomic write via tmp + rename so hypr-drag-hint never reads a partial scene
    local f = io.open(scene_tmp_path, "w")
    if not f then return end
    f:write(content)
    f:close()
    os.rename(scene_tmp_path, scene_path)
end

------------------------------------------------------------
-- Binary Tree Operations
------------------------------------------------------------

local function clone_tree(node)
    if not node then return nil end
    if node.kind == "leaf" then
        return { kind = "leaf", addr = node.addr }
    end
    return {
        kind = "split",
        dir = node.dir,
        ratio = node.ratio,
        first = clone_tree(node.first),
        second = clone_tree(node.second),
    }
end

local function count_leaves(node)
    if not node then return 0 end
    if node.kind == "leaf" then return 1 end
    return count_leaves(node.first) + count_leaves(node.second)
end

local function find_leaf(node, addr, parent)
    if not node then return nil, nil end
    if node.kind == "leaf" then
        if node.addr == addr then
            return node, parent
        end
        return nil, nil
    end
    local f, p = find_leaf(node.first, addr, node)
    if f then return f, p end
    return find_leaf(node.second, addr, node)
end

-- Remove a leaf and collapse its parent split node (preserving all other ratios).
local function prune_leaf(node, addr)
    if not node then return nil, false end
    if node.kind == "leaf" then
        if node.addr == addr then
            return nil, true
        end
        return node, false
    end

    local new_first, removed_first = prune_leaf(node.first, addr)
    if removed_first then
        if not new_first then
            return node.second, true
        end
        node.first = new_first
        return node, true
    end

    local new_second, removed_second = prune_leaf(node.second, addr)
    if removed_second then
        if not new_second then
            return node.first, true
        end
        node.second = new_second
        return node, true
    end

    return node, false
end

-- Split a specific target leaf into two children on the requested side.
local function insert_at_leaf(node, target_addr, new_addr, side)
    if not node then
        return { kind = "leaf", addr = new_addr }, true
    end
    if node.kind == "leaf" then
        if node.addr == target_addr then
            local dir = (side == "left" or side == "right") and "h" or "v"
            local new_leaf = { kind = "leaf", addr = new_addr }
            if side == "left" or side == "top" then
                return { kind = "split", dir = dir, ratio = 0.5, first = new_leaf, second = node }, true
            else
                return { kind = "split", dir = dir, ratio = 0.5, first = node, second = new_leaf }, true
            end
        end
        return node, false
    end
    local nf, ok = insert_at_leaf(node.first, target_addr, new_addr, side)
    if ok then
        node.first = nf
        return node, true
    end
    local ns, ok2 = insert_at_leaf(node.second, target_addr, new_addr, side)
    if ok2 then
        node.second = ns
        return node, true
    end
    return node, false
end

-- Wrap the entire root tree with a new split along an outer monitor border.
local function insert_at_root(root, new_addr, side)
    local new_leaf = { kind = "leaf", addr = new_addr }
    if not root then
        return new_leaf
    end
    local dir = (side == "left" or side == "right") and "h" or "v"
    if side == "left" or side == "top" then
        return { kind = "split", dir = dir, ratio = 0.5, first = new_leaf, second = root }
    else
        return { kind = "split", dir = dir, ratio = 0.5, first = root, second = new_leaf }
    end
end

-- Swap two leaves in the same tree.
-- Direct siblings flip parent.ratio so each window keeps its own size!
local function swap_leaves(root, addr_a, addr_b)
    if not root or addr_a == addr_b then return false end
    local la, pa = find_leaf(root, addr_a, nil)
    local lb, pb = find_leaf(root, addr_b, nil)
    if not la or not lb then return false end

    la.addr, lb.addr = lb.addr, la.addr
    if pa and pa == pb then
        pa.ratio = clamp(1.0 - pa.ratio, MIN_RATIO, MAX_RATIO)
    end
    return true
end

-- Replace a leaf's address in-place (used for cross-workspace swap).
local function replace_leaf_addr(root, old_addr, new_addr)
    local l = find_leaf(root, old_addr, nil)
    if l then
        l.addr = new_addr
        return true
    end
    return false
end

-- Compute bounding boxes for every leaf in the tree.
local function compute_rects(node, box, out)
    if not node then return end
    if node.kind == "leaf" then
        out[node.addr] = { x = box.x, y = box.y, w = box.w, h = box.h }
        return
    end
    if node.dir == "h" then
        local w1 = box.w * node.ratio
        compute_rects(node.first,  { x = box.x,      y = box.y, w = w1,         h = box.h }, out)
        compute_rects(node.second, { x = box.x + w1, y = box.y, w = box.w - w1, h = box.h }, out)
    else
        local h1 = box.h * node.ratio
        compute_rects(node.first,  { x = box.x, y = box.y,      w = box.w, h = h1         }, out)
        compute_rects(node.second, { x = box.x, y = box.y + h1, w = box.w, h = box.h - h1 }, out)
    end
end

-- Find the nearest ancestor split of `addr` matching `want_dir` (or immediate parent if nil).
local function find_ancestor_split(node, addr, want_dir)
    if not node or node.kind == "leaf" then return nil, false end
    local found_in_first = (node.first.kind == "leaf" and node.first.addr == addr)
    local found_in_second = (node.second.kind == "leaf" and node.second.addr == addr)

    if found_in_first or found_in_second then
        if not want_dir or node.dir == want_dir then
            return node, true, found_in_first
        end
        return nil, true, found_in_first
    end

    local anc, in_sub, is_first = find_ancestor_split(node.first, addr, want_dir)
    if in_sub then
        if anc then return anc, true, is_first end
        if not want_dir or node.dir == want_dir then
            return node, true, true
        end
        return nil, true, true
    end

    local anc2, in_sub2, is_first2 = find_ancestor_split(node.second, addr, want_dir)
    if in_sub2 then
        if anc2 then return anc2, true, is_first2 end
        if not want_dir or node.dir == want_dir then
            return node, true, false
        end
        return nil, true, false
    end

    return nil, false, false
end

-- Find the leaf whose box contains (mx, my), else the closest leaf.
local function leaf_at_point(rects, mx, my, exclude_addr)
    for addr, r in pairs(rects) do
        if addr ~= exclude_addr and
           mx >= r.x and mx <= r.x + r.w and
           my >= r.y and my <= r.y + r.h then
            return addr, r
        end
    end
    local best_addr, best_r, best_d2 = nil, nil, math.huge
    for addr, r in pairs(rects) do
        if addr ~= exclude_addr then
            local qx = clamp(mx, r.x, r.x + r.w)
            local qy = clamp(my, r.y, r.y + r.h)
            local dx, dy = mx - qx, my - qy
            local d2 = dx * dx + dy * dy
            if d2 < best_d2 then
                best_d2 = d2
                best_addr, best_r = addr, r
            end
        end
    end
    return best_addr, best_r
end

------------------------------------------------------------
-- Hyprland Layout Provider (hl.layout.register("bsp", ...))
------------------------------------------------------------

local function sync_tree(ws_id, area, targets)
    local present = {}
    local target_order = {}
    for _, t in ipairs(targets) do
        local w = t.window
        if w and w.address then
            local a = norm_addr(w.address)
            present[a] = t
            target_order[#target_order + 1] = a
        end
    end

    local root = trees[ws_id]

    -- 1. Prune leaves that disappeared from this workspace
    local function prune_missing(node)
        if not node then return nil end
        if node.kind == "leaf" then
            if present[node.addr] then return node end
            return nil
        end
        local nf = prune_missing(node.first)
        local ns = prune_missing(node.second)
        if not nf then return ns end
        if not ns then return nf end
        node.first = nf
        node.second = ns
        return node
    end
    root = prune_missing(root)

    -- 2. Insert newly added windows
    for _, addr in ipairs(target_order) do
        if not find_leaf(root, addr, nil) then
            local op = pending_ops[addr]
            if op and op.ws_id == ws_id then
                pending_ops[addr] = nil
                if op.kind == "root" then
                    root = insert_at_root(root, addr, op.side)
                elseif op.kind == "local" and op.target_addr and find_leaf(root, op.target_addr, nil) then
                    root = insert_at_leaf(root, op.target_addr, addr, op.side)
                else
                    root = insert_at_root(root, addr, "right")
                end
            else
                -- Default insertion: split active or hovered leaf along its longer axis
                if not root then
                    root = { kind = "leaf", addr = addr }
                else
                    local rects = {}
                    compute_rects(root, area, rects)
                    local active = hl.get_active_window()
                    local target_addr = nil
                    if active and active.address then
                        local aa = norm_addr(active.address)
                        if aa ~= addr and rects[aa] then
                            target_addr = aa
                        end
                    end
                    if not target_addr then
                        local pos = hl.get_cursor_pos()
                        if pos then
                            target_addr = leaf_at_point(rects, pos.x, pos.y, addr)
                        end
                    end
                    if not target_addr then
                        for a in pairs(rects) do target_addr = a; break end
                    end
                    local tr = rects[target_addr]
                    local side = (tr and tr.w >= tr.h) and "right" or "bottom"
                    root = insert_at_leaf(root, target_addr, addr, side)
                end
            end
        end
    end

    trees[ws_id] = root
    return root, present
end

local function provider_recalculate(ctx)
    if not ctx or not ctx.targets or #ctx.targets == 0 then
        return
    end
    local first_win = ctx.targets[1].window
    if not first_win or not first_win.workspace or not first_win.workspace.id then
        return
    end
    local ws_id = first_win.workspace.id
    local area = { x = ctx.area.x, y = ctx.area.y, w = ctx.area.w, h = ctx.area.h }
    ws_areas[ws_id] = area

    local root, present = sync_tree(ws_id, area, ctx.targets)
    if not root then return end

    local rects = {}
    compute_rects(root, area, rects)
    for addr, r in pairs(rects) do
        local t = present[addr]
        if t then
            t:place(r)
        end
    end
end

local function find_neighbor_in_dir(rects, my_addr, dir)
    local me = rects[my_addr]
    if not me then return nil end
    local mcx = me.x + me.w * 0.5
    local mcy = me.y + me.h * 0.5
    local best_addr, best_score = nil, math.huge

    for addr, r in pairs(rects) do
        if addr ~= my_addr then
            local rcx = r.x + r.w * 0.5
            local rcy = r.y + r.h * 0.5
            local dx, dy = rcx - mcx, rcy - mcy
            local ok = false
            local primary, secondary = 0, 0
            if dir == "l" and dx < -5 then
                ok = true; primary = -dx; secondary = math.abs(dy)
            elseif dir == "r" and dx > 5 then
                ok = true; primary = dx; secondary = math.abs(dy)
            elseif dir == "u" and dy < -5 then
                ok = true; primary = -dy; secondary = math.abs(dx)
            elseif dir == "d" and dy > 5 then
                ok = true; primary = dy; secondary = math.abs(dx)
            end
            if ok then
                local score = primary + secondary * 2.0
                if score < best_score then
                    best_score = score
                    best_addr = addr
                end
            end
        end
    end
    return best_addr
end

local function provider_layout_msg(ctx, msg)
    if not ctx or not ctx.targets or #ctx.targets == 0 then
        return true
    end
    local first_win = ctx.targets[1].window
    if not first_win or not first_win.workspace or not first_win.workspace.id then
        return true
    end
    local ws_id = first_win.workspace.id
    local area = { x = ctx.area.x, y = ctx.area.y, w = ctx.area.w, h = ctx.area.h }
    ws_areas[ws_id] = area
    local root = sync_tree(ws_id, area, ctx.targets)
    if not root then return true end

    if msg == "recalc" then
        return true
    end

    local active = hl.get_active_window()
    local active_addr = active and active.address and norm_addr(active.address) or nil

    -- splitratio <delta> [exact]
    local sr_arg = msg:match("^splitratio%s+(.+)$")
    if sr_arg and active_addr then
        local num_str, mode = sr_arg:match("^([%+%-]?[%d%.]+)%s*(.*)$")
        local val = tonumber(num_str)
        if val then
            local anc = find_ancestor_split(root, active_addr, nil)
            if anc then
                if mode == "exact" then
                    anc.ratio = clamp(val, MIN_RATIO, MAX_RATIO)
                else
                    anc.ratio = clamp(anc.ratio + val, MIN_RATIO, MAX_RATIO)
                end
            end
        end
        return true
    end

    -- swapdir <l|r|u|d>
    local sdir = msg:match("^swapdir%s+([lrud])")
    if sdir and active_addr then
        local rects = {}
        compute_rects(root, area, rects)
        local neighbor = find_neighbor_in_dir(rects, active_addr, sdir)
        if neighbor then
            swap_leaves(root, active_addr, neighbor)
        end
        return true
    end

    -- togglesplit
    if msg == "togglesplit" and active_addr then
        local anc = find_ancestor_split(root, active_addr, nil)
        if anc then
            anc.dir = (anc.dir == "h") and "v" or "h"
        end
        return true
    end

    return true
end

------------------------------------------------------------
-- Drop Zone Evaluation & Exact Tree Preview
------------------------------------------------------------

local function evaluate_drop(dragged_addr, src_ws_id, mx, my)
    local mon = hl.get_monitor_at(mx, my)
    if not mon then return nil end

    local ws = mon.active_special_workspace or mon.active_workspace
    if not ws or not ws.id then return nil end
    if ws.has_fullscreen then return nil end

    local dst_ws_id = ws.id
    local area = mon_work_area(mon, dst_ws_id)
    local mr = mon_logical_rect(mon)
    local root = trees[dst_ws_id]

    -- Count tiled windows excluding dragged
    local live_rects = {}
    if root then
        compute_rects(root, area, live_rects)
    end
    local other_count = 0
    for a in pairs(live_rects) do
        if a ~= dragged_addr then other_count = other_count + 1 end
    end

    -- Case 0: empty destination workspace
    if other_count == 0 then
        local sim_rects = { [dragged_addr] = area }
        return {
            mon = mon, mr = mr, dst_ws_id = dst_ws_id, area = area,
            kind = (dst_ws_id ~= src_ws_id) and "empty" or "none",
            side = "none",
            sim_rects = sim_rects,
        }
    end

    -- Tier 1: Outer monitor border -> Root-Edge full vertical/horizontal split
    if other_count >= 2 then
        local d_left   = mx - area.x
        local d_right  = (area.x + area.w) - mx
        local d_top    = my - area.y
        local d_bottom = (area.y + area.h) - my
        local min_d = ROOT_EDGE_PX + 1
        local edge = nil
        if d_left >= -20 and d_left <= ROOT_EDGE_PX and d_left < min_d then min_d = d_left; edge = "left" end
        if d_right >= -20 and d_right <= ROOT_EDGE_PX and d_right < min_d then min_d = d_right; edge = "right" end
        if d_top >= -20 and d_top <= ROOT_EDGE_PX and d_top < min_d then min_d = d_top; edge = "top" end
        if d_bottom >= -20 and d_bottom <= ROOT_EDGE_PX and d_bottom < min_d then edge = "bottom" end

        if edge then
            local sim = clone_tree(root)
            if dst_ws_id == src_ws_id then
                sim = prune_leaf(sim, dragged_addr)
            end
            sim = insert_at_root(sim, dragged_addr, edge)
            local sim_rects = {}
            compute_rects(sim, area, sim_rects)
            return {
                mon = mon, mr = mr, dst_ws_id = dst_ws_id, area = area,
                kind = "root", side = edge,
                sim_rects = sim_rects,
            }
        end
    end

    -- Hovering back over the dragged window itself -> no-op
    local my_rect = (dst_ws_id == src_ws_id) and live_rects[dragged_addr] or nil
    if my_rect and
       mx >= my_rect.x and mx <= my_rect.x + my_rect.w and
       my >= my_rect.y and my <= my_rect.y + my_rect.h then
        return {
            mon = mon, mr = mr, dst_ws_id = dst_ws_id, area = area,
            kind = "none", side = "none",
            sim_rects = live_rects,
        }
    end

    -- Find hovered (or closest) other tiled window
    local target_addr, tr = leaf_at_point(live_rects, mx, my, dragged_addr)
    if not target_addr or not tr then return nil end

    -- Tier 2: Center of target window -> In-place swap (direct siblings flip ratio!)
    local rx = (tr.w > 0) and ((mx - tr.x) / tr.w) or 0.5
    local ry = (tr.h > 0) and ((my - tr.y) / tr.h) or 0.5
    if rx >= CENTER_MARGIN and rx <= (1.0 - CENTER_MARGIN) and
       ry >= CENTER_MARGIN and ry <= (1.0 - CENTER_MARGIN) then
        local sim = clone_tree(root)
        local glyph_side = "left"
        if dst_ws_id == src_ws_id then
            local la, pa = find_leaf(sim, dragged_addr, nil)
            local lb, pb = find_leaf(sim, target_addr, nil)
            if pa and pa == pb then
                glyph_side = (pa.dir == "v") and "top" or "left"
            elseif my_rect then
                local vdist = math.abs((tr.y + tr.h * 0.5) - (my_rect.y + my_rect.h * 0.5))
                local hdist = math.abs((tr.x + tr.w * 0.5) - (my_rect.x + my_rect.w * 0.5))
                glyph_side = (vdist > hdist) and "top" or "left"
            end
            swap_leaves(sim, dragged_addr, target_addr)
        else
            replace_leaf_addr(sim, target_addr, dragged_addr)
        end
        local sim_rects = {}
        compute_rects(sim, area, sim_rects)
        return {
            mon = mon, mr = mr, dst_ws_id = dst_ws_id, area = area,
            kind = "swap", target_addr = target_addr, side = glyph_side,
            sim_rects = sim_rects,
        }
    end

    -- Tier 3: 4-triangle local split around target window
    local cx, cy = tr.x + tr.w * 0.5, tr.y + tr.h * 0.5
    local dx, dy = mx - cx, my - cy
    local prop = (tr.w > 0) and (tr.h / tr.w) or 1.0
    local slope = (math.abs(dx) > 1e-6) and math.abs(dy / dx) or 1e9
    local side
    if slope < prop then
        side = (dx > 0) and "right" or "left"
    else
        side = (dy > 0) and "bottom" or "top"
    end

    local sim = clone_tree(root)
    if dst_ws_id == src_ws_id then
        sim = prune_leaf(sim, dragged_addr)
    end
    sim = insert_at_leaf(sim, target_addr, dragged_addr, side)
    local sim_rects = {}
    compute_rects(sim, area, sim_rects)
    return {
        mon = mon, mr = mr, dst_ws_id = dst_ws_id, area = area,
        kind = "local", target_addr = target_addr, side = side,
        sim_rects = sim_rects,
    }
end

local function publish_preview()
    if not drag_state then return end
    local pos = hl.get_cursor_pos()
    if not pos then return end

    local eval = evaluate_drop(drag_state.addr, drag_state.src_ws_id, pos.x, pos.y)
    drag_state.last_eval = eval
    if not eval then
        write_scene("hide\n")
        return
    end

    local gap_in = 10
    local mon = eval.mon
    local mr = eval.mr
    local gx = pos.x - mr.x
    local gy = pos.y - mr.y

    local lines = {
        string.format("scene %s %.1f %.1f %.1f %.1f",
            mon.name, gx, gy, drag_state.ghost_w, drag_state.ghost_h),
    }

    for addr, r in pairs(eval.sim_rects) do
        local is_dragged = (addr == drag_state.addr) and 1 or 0
        local is_partner = (eval.target_addr and addr == eval.target_addr) and 1 or 0
        local is_root = (is_dragged == 1 and eval.kind == "root") and 1 or 0
        local is_swap = (is_dragged == 1 and eval.kind == "swap") and 1 or 0
        local side = (is_dragged == 1) and eval.side or "none"

        -- Inset by gaps_in so preview matches Hyprland's rendered window gap
        local lx = (r.x - mr.x) + gap_in
        local ly = (r.y - mr.y) + gap_in
        local lw = math.max(8, r.w - gap_in * 2)
        local lh = math.max(8, r.h - gap_in * 2)

        lines[#lines + 1] = string.format(
            "tile %s %.1f %.1f %.1f %.1f %d %d %d %d %s",
            is_dragged == 1 and "__dragged__" or addr,
            lx, ly, lw, lh,
            is_dragged, is_partner, is_root, is_swap, side)
    end

    write_scene(table.concat(lines, "\n") .. "\n")
end

local function commit_drop()
    if not drag_state then return end
    local st = drag_state
    drag_state = nil
    if drag_timer then
        drag_timer:set_enabled(false)
    end
    write_scene("hide\n")

    local eval = st.last_eval
    if not eval or eval.kind == "none" then
        return
    end

    local addr = st.addr
    local src_ws = st.src_ws_id
    local dst_ws = eval.dst_ws_id

    if dst_ws == src_ws then
        -- Same workspace: mutate tree directly and recalculate!
        local root = trees[dst_ws]
        if eval.kind == "swap" and eval.target_addr then
            swap_leaves(root, addr, eval.target_addr)
        elseif eval.kind == "local" and eval.target_addr then
            root = prune_leaf(root, addr)
            root = insert_at_leaf(root, eval.target_addr, addr, eval.side)
            trees[dst_ws] = root
        elseif eval.kind == "root" then
            root = prune_leaf(root, addr)
            root = insert_at_root(root, addr, eval.side)
            trees[dst_ws] = root
        end
        hl.dispatch(hl.dsp.focus({ monitor = eval.mon.name }))
        hl.dispatch(hl.dsp.layout("recalc"))
        hl.dispatch(hl.dsp.focus({ window = "address:" .. full_addr(addr) }))
    else
        -- Cross-workspace move / swap
        if eval.kind == "swap" and eval.target_addr then
            if trees[src_ws] then
                replace_leaf_addr(trees[src_ws], addr, eval.target_addr)
            end
            if trees[dst_ws] then
                replace_leaf_addr(trees[dst_ws], eval.target_addr, addr)
            end
            hl.dispatch(hl.dsp.window.move({ workspace = dst_ws, window = "address:" .. full_addr(addr) }))
            hl.dispatch(hl.dsp.window.move({ workspace = src_ws, window = "address:" .. full_addr(eval.target_addr) }))
        else
            if trees[src_ws] then
                trees[src_ws] = prune_leaf(trees[src_ws], addr)
            end
            pending_ops[addr] = {
                ws_id = dst_ws,
                kind = eval.kind,
                target_addr = eval.target_addr,
                side = eval.side,
            }
            hl.dispatch(hl.dsp.window.move({ workspace = dst_ws, window = "address:" .. full_addr(addr) }))
        end
        hl.dispatch(hl.dsp.focus({ window = "address:" .. full_addr(addr) }))
    end
end

------------------------------------------------------------
-- Mouse-Resize Support for Tiled Windows (Super + RMB)
------------------------------------------------------------

local function tick_resize()
    if not resize_state then return end
    local pos = hl.get_cursor_pos()
    if not pos then return end

    local dx = pos.x - resize_state.start_x
    local dy = pos.y - resize_state.start_y
    local changed = false

    if resize_state.h_split and resize_state.h_span > 20 then
        local nr = clamp(resize_state.h_start_ratio + dx / resize_state.h_span, MIN_RATIO, MAX_RATIO)
        if math.abs(nr - resize_state.h_split.ratio) > 0.002 then
            resize_state.h_split.ratio = nr
            changed = true
        end
    end
    if resize_state.v_split and resize_state.v_span > 20 then
        local nr = clamp(resize_state.v_start_ratio + dy / resize_state.v_span, MIN_RATIO, MAX_RATIO)
        if math.abs(nr - resize_state.v_split.ratio) > 0.002 then
            resize_state.v_split.ratio = nr
            changed = true
        end
    end

    if changed then
        hl.dispatch(hl.dsp.layout("recalc"))
    end
end

------------------------------------------------------------
-- Window Hit-Testing & Public Setup
------------------------------------------------------------

local function window_at_cursor()
    local pos = hl.get_cursor_pos()
    local mon = hl.get_monitor_at_cursor()
    if not pos or not mon then return nil end
    local ws = mon.active_special_workspace or mon.active_workspace
    if not ws then return nil end

    local wins = hl.get_windows({ workspace = ws, mapped = true })
    local tiled_hit = nil
    for _, w in ipairs(wins) do
        if not w.hidden then
            local b = box_xywh(w.at, w.size)
            if b and pos.x >= b.x and pos.x <= b.x + b.w and pos.y >= b.y and pos.y <= b.y + b.h then
                if w.floating then
                    return w
                end
                tiled_hit = w
            end
        end
    end
    return tiled_hit
end

function M.register()
    hl.layout.register("bsp", {
        recalculate = provider_recalculate,
        layout_msg = provider_layout_msg,
    })
end

function M.bind_mouse(mainMod)
    drag_timer = hl.timer(publish_preview, { timeout = 16, type = "repeat" })
    drag_timer:set_enabled(false)

    resize_timer = hl.timer(tick_resize, { timeout = 16, type = "repeat" })
    resize_timer:set_enabled(false)

    -- Super + LMB: frozen-background BSP drag for tiled windows, native drag for floating
    hl.bind(mainMod .. " + mouse:272", function()
        local win = window_at_cursor()
        if not win then return end
        if win.floating then
            hl.dispatch(hl.dsp.window.drag())
            return
        end
        if not win.workspace or not win.workspace.id then return end

        local b = box_xywh(win.at, win.size)
        local aspect = (b and b.h > 10) and clamp(b.w / b.h, 0.5, 2.2) or 1.5
        drag_state = {
            addr = norm_addr(win.address),
            src_ws_id = win.workspace.id,
            ghost_h = 56.0,
            ghost_w = 56.0 * aspect,
            last_eval = nil,
        }
        publish_preview()
        drag_timer:set_enabled(true)
    end)

    hl.bind("mouse:272", function()
        if drag_state then
            commit_drop()
        end
    end, { release = true, ignore_mods = true, non_consuming = true })

    -- Super + RMB: live BSP split-ratio resize for tiled windows, native resize for floating
    hl.bind(mainMod .. " + mouse:273", function()
        local win = window_at_cursor()
        if not win then return end
        if win.floating then
            hl.dispatch(hl.dsp.window.resize())
            return
        end
        if not win.workspace or not win.workspace.id then return end
        local ws_id = win.workspace.id
        local root = trees[ws_id]
        local pos = hl.get_cursor_pos()
        if not root or not pos then return end

        local addr = norm_addr(win.address)
        local h_split = find_ancestor_split(root, addr, "h")
        local v_split = find_ancestor_split(root, addr, "v")
        if not h_split and not v_split then return end

        local area = ws_areas[ws_id] or { x = 0, y = 0, w = 1920, h = 1080 }
        -- Find split container spans for proportional mouse tracking
        local h_span, v_span = area.w, area.h
        local function find_box(node, box)
            if not node or node.kind == "leaf" then return end
            if node == h_split then h_span = box.w end
            if node == v_split then v_span = box.h end
            if node.dir == "h" then
                local w1 = box.w * node.ratio
                find_box(node.first,  { x = box.x,      y = box.y, w = w1,         h = box.h })
                find_box(node.second, { x = box.x + w1, y = box.y, w = box.w - w1, h = box.h })
            else
                local h1 = box.h * node.ratio
                find_box(node.first,  { x = box.x, y = box.y,      w = box.w, h = h1         })
                find_box(node.second, { x = box.x, y = box.y + h1, w = box.w, h = box.h - h1 })
            end
        end
        find_box(root, area)

        hl.dispatch(hl.dsp.focus({ window = "address:" .. full_addr(addr) }))
        resize_state = {
            start_x = pos.x,
            start_y = pos.y,
            h_split = h_split,
            h_start_ratio = h_split and h_split.ratio or 0.5,
            h_span = h_span,
            v_split = v_split,
            v_start_ratio = v_split and v_split.ratio or 0.5,
            v_span = v_span,
        }
        resize_timer:set_enabled(true)
    end)

    hl.bind("mouse:273", function()
        if resize_state then
            resize_state = nil
            resize_timer:set_enabled(false)
        end
    end, { release = true, ignore_mods = true, non_consuming = true })
end

return M
