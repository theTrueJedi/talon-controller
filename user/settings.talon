# Evan's overrides of community settings. `os: mac` makes this context more
# specific than community/settings.talon (no header), so these values win.
os: mac
-
settings():
    # Community's pop handler runs even in sleep mode and releases EVERY held
    # mouse button, including physically held ones. Mouse/keyboard clicks can
    # register as "pop", so real click-and-drags got dropped.
    user.mouse_enable_pop_stops_drag = false
