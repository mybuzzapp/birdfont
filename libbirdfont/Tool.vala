/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

public class Tool : Widget {
	
	public double x = 0;
	public double y = 0;
	public double w = 33 * Toolbox.get_scale ();
	public double h = (33 / 1.11) * Toolbox.get_scale ();

	double scale;
			
	public bool active = false;
	public bool selected = false;
	
	Text icon_font;
	ImageSurface? icon = null;
		
	public signal void select_action (Tool selected);
	public signal void deselect_action (Tool selected);
	
	public signal void press_action (Tool selected, int button, int x, int y);
	public signal void double_click_action (Tool selected, int button, int x, int y);
	public signal void move_action (Tool selected, int x, int y);
	public signal void move_out_action (Tool selected);
	public signal void release_action (Tool selected, int button, int x, int y);
	
	/** Returns true if tool is listening for scroll wheel actions. */
	public signal bool scroll_wheel_up_action (Tool selected);
	public signal bool scroll_wheel_down_action (Tool selected);
	
	public signal void key_press_action (Tool selected, uint32 keyval);
	public signal void key_release_action (Tool selected, uint32 keyval);
	
	public signal void panel_press_action (Tool selected, uint button, double x, double y);
	public signal void panel_release_action (Tool selected, uint button, double x, double y);

	/** @return true is event is consumed. */
	public signal bool panel_move_action (Tool selected, double x, double y);
	
	public signal void draw_action (Tool selected, Context cr, Glyph glyph);
	
	public string name = "";
	
	static int next_id = 1;
	
	int id;
	
	public bool new_selection = false;
	
	bool show_bg = true;
	
	public string tip = "";

	// keyboard bindings
	public uint modifier_flag;
	public unichar key;
	
	public bool persistent = false;
	public bool editor_events = false;
	
	bool waiting_for_tooltip = false;
	bool showing_this_tooltip = false;
	static Tool active_tooltip = new Tool ();
	
	bool visible = true;
	public bool is_tool_modifier = false;
	
	/** Create tool with a certain name and load icon "name".png */
	public Tool (string? name = null, string tip = "") {
		this.tip = tip;
		
		icon_font = new Text ();
		
		scale = w / 111.0; // scale to 320 dpi
		
		if (name != null) {
			set_icon ((!) name);
			this.name = (!) name;
		}
				
		id = next_id;
		next_id++;
		
		panel_press_action.connect ((self, button, x, y) => {
		});
		
		move_out_action.connect ((self) => {
			MainWindow.get_toolbox ().hide_tooltip ();
			active_tooltip.showing_this_tooltip = false;
		});
		
		panel_move_action.connect ((self, x, y) => {
			if (is_active ()) {
				wait_for_tooltip ();
			}
			return false;
		});
	}

	public override double get_height () {
		return 33 * scale;
	}

	public override double get_width () {
		return 33 * scale;
	}
	
	public void set_tool_visibility (bool v) {
		visible = v;
	}

	public bool tool_is_visible () {
		return visible;
	}

	void wait_for_tooltip () {
		TimeoutSource timer_show;
		int timeout_interval = 1500;
		
		if (active_tooltip != this) {
			if (active_tooltip.showing_this_tooltip) {
				timeout_interval = 1;
			}
			
			active_tooltip.showing_this_tooltip = false;
			showing_this_tooltip = false;
			active_tooltip = this;

			if (!waiting_for_tooltip) {
				waiting_for_tooltip = true;
				timer_show = new TimeoutSource (timeout_interval);
				timer_show.set_callback (() => {
					if (tip != "" && active_tooltip.is_active () && !active_tooltip.showing_this_tooltip) {
						show_tooltip ();
					}
					waiting_for_tooltip = false;
					return waiting_for_tooltip;
				});
				timer_show.attach (null);
			}
		}
	}
	
	public static void show_tooltip () {
		TimeoutSource timer_hide;
		Toolbox toolbox;
		
		toolbox = MainWindow.get_toolbox ();
		
		// hide tooltip label later
		if (!active_tooltip.showing_this_tooltip) {
			timer_hide = new TimeoutSource (1500);
			timer_hide.set_callback (() => {
				if (!active_tooltip.is_active ()) {
					toolbox.hide_tooltip ();
					active_tooltip.showing_this_tooltip = false;
					active_tooltip = new Tool ();
				}				
				return active_tooltip.showing_this_tooltip;
			});
			timer_hide.attach (null);
		}
		
		active_tooltip.showing_this_tooltip = true;
			
		toolbox.hide_tooltip ();
		toolbox.show_tooltip (active_tooltip.tip, (int) active_tooltip.x, (int) active_tooltip.y);
	}
	
	public void set_icon (string name) {
		bool found;
		string icon_file;
		
		icon_file = Theme.get_icon_file ();
		icon_font = new Text ((!) name);
		found = icon_font.load_font (icon_file);
		icon_font.use_cache (true);
		icon_font.set_font_size (35);
		
		if (!found) {
			warning (@"Icon font for toolbox was not found. ($(icon_file))");
		}
	}
	
	public bool is_active () {
		return active;
	}
	
	public void set_show_background (bool bg) {
		show_bg = bg;
	}
	
	public int get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public bool is_selected () {
		return selected;
	}
	
	public string get_tip () {
		return tip;
	}

	public new bool is_over (double xp, double yp) {
		bool r = (x <= xp <= x + w  && y <= yp <= y + h);
		return r;
	}
	
	public bool set_selected (bool a) {						
		new_selection = true;
		selected = a;
		set_active (a);
		
		if (!a) {
			deselect_action (this);
		}
		
		return true;
	}
	
	/** @return true if this tool changes state, */
	public bool set_active (bool ac) {
		bool ret = (active != ac);
		active = ac;	
		return ret;
	}
	
	public override void draw (Context cr) {
		double xt = x;
		double yt = y;
		
		double bgx, bgy;
		double iconx, icony;
		
		string border = "Button Border 3";
		string background = "Button Border 3";
		
		cr.save ();
			
		bgx = xt;
		bgy = yt;

		// Button in four states
		if (selected) {
			border = "Button Border 1";
			background = "Button Background 1";
		}

		if (selected && active) {
			border = "Button Border 2";
			background = "Button Background 2";
		}

		if (!selected) {
			border = "Button Border 3";
			background = "Button Background 3";
		}

		if (!selected && active) {
			border = "Button Border 4";
			background = "Button Background 4";
		}

		Theme.color (cr, background);
		draw_rounded_rectangle (cr, bgx, bgy, 34, 28, 4);
		cr.fill ();
				
		cr.set_line_width (1);
		Theme.color (cr, border);
		draw_rounded_rectangle (cr, bgx, bgy, 34, 28, 4);
		cr.stroke ();
		
		iconx = bgx + w / 2 - icon_font.get_sidebearing_extent () / 2;
		icony = bgy + h / 2 - icon_font.get_height () / 2;
		
		if (!selected) {
			Theme.text_color (icon_font, "Tool Foreground");
		} else {
			Theme.text_color (icon_font, "Selected Tool Foreground");
		}	
		
		icon_font.widget_x = iconx;
		icon_font.widget_y = icony;

		icon_font.draw (cr);
		
		cr.restore ();
	}

	/** Run pending events in main loop before continuing. */
	public static void @yield () {
		int t = 0;
		TimeoutSource time = new TimeoutSource (500);
		bool timeout;
		unowned MainContext context;
		bool acquired;

		if (TestBirdFont.is_slow_test ()) {
			timeout = false;
			
			time.set_callback (() => {
				timeout = true;
				return false;
			});

			time.attach (null);		
		} else {
			timeout = true;
		}
    
		context = MainContext.default ();
		acquired = context.acquire ();
		
		if (unlikely (!acquired)) {
			warning ("Failed to acquire main loop.\n");
			return;
		}

		while (context.pending () || TestBirdFont.is_slow_test ()) {
			context.iteration (true);
			t++;

			if (!context.pending () && TestBirdFont.is_slow_test ()) {
				if (timeout) break;
			}
		}
		
		context.release ();
	}
	
	public void set_persistent (bool p) {
		persistent = p;
	}
}

}
