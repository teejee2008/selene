/*
 * SimpleProgressWindow.vala
 *
 * Copyright 2015 Tony George <teejee2008@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */


using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class SimpleProgressWindow : Window {
	private Gtk.Box vbox_main;
	private Gtk.Spinner spinner;
	private Gtk.Label lbl_msg;
	private Gtk.Label lbl_status;
	private ProgressBar progressbar;
	
	private uint tmr_init = 0;
	private uint tmr_pulse = 0;
	private uint tmr_close = 0;
	private int def_width = 400;
	private int def_height = 50;

	private string status_message;
	// init
	
	public SimpleProgressWindow.with_parent(Window parent, string message) {
		set_transient_for(parent);
		set_modal(true);
		set_skip_taskbar_hint(true);
		set_skip_pager_hint(true);
		window_position = WindowPosition.CENTER;

		App.status_line = "";
		App.progress_count = 0;
		App.progress_total = 0;
		
		status_message = message;
		
		init_window();
	}

	public void init_window () {
		title = "";
		icon = get_app_icon(16);
		resizable = false;
		deletable = false;
		
		//vbox_main
		vbox_main = new Box (Orientation.VERTICAL, 6);
		vbox_main.margin = 6;
		vbox_main.set_size_request (def_width, def_height);
		add (vbox_main);

		var hbox_status = new Box (Orientation.HORIZONTAL, 3);
		hbox_status.margin_top = 6;
		vbox_main.add (hbox_status);
		
		spinner = new Gtk.Spinner();
		spinner.active = true;
		hbox_status.add(spinner);
		
		//lbl_msg
		lbl_msg = new Label (status_message);
		lbl_msg.halign = Align.START;
		lbl_msg.ellipsize = Pango.EllipsizeMode.END;
		lbl_msg.max_width_chars = 50;
		lbl_msg.margin_bottom = 3;
		lbl_msg.margin_left = 3;
		lbl_msg.margin_right = 3;
		hbox_status.add (lbl_msg);

		//progressbar
		progressbar = new ProgressBar();
		progressbar.margin_bottom = 3;
		progressbar.margin_left = 3;
		progressbar.margin_right = 3;
		//progressbar.set_size_request(-1, 25);
		progressbar.pulse_step = 0.1;
		vbox_main.pack_start (progressbar, false, true, 0);

		//lbl_status
		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		lbl_status.max_width_chars = 50;
		lbl_status.margin_bottom = 3;
		lbl_status.margin_left = 3;
		lbl_status.margin_right = 3;
		vbox_main.pack_start (lbl_status, false, true, 0);
		
		show_all();

		tmr_init = Timeout.add(100, init_delayed);
	}

	private bool init_delayed() {
		/* any actions that need to run after window has been displayed */
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		//start();
		
		return false;
	}


	// common

	public void pulse_start(){
		tmr_pulse = Timeout.add(100, pulse_timeout);
	}

	private bool pulse_timeout(){
		if (tmr_pulse > 0) {
			Source.remove(tmr_pulse);
			tmr_pulse = 0;
		}
			
		progressbar.pulse();
		gtk_do_events();

		tmr_pulse = Timeout.add(100, pulse_timeout);
		return true;
	}
	
	public void pulse_stop(){
		if (tmr_pulse > 0) {
			Source.remove(tmr_pulse);
			tmr_pulse = 0;
		}
	}

	public void update_message(string msg){
		if (msg.length > 0){
			lbl_msg.label = msg;
		}
	}

	public void update_status_line(bool clear = false){
		if (clear){
			lbl_status.label = "";
		}
		else{
			lbl_status.label = App.status_line;
		}
	}
	
	public void update_progressbar(){
		double fraction = App.progress_count / (App.progress_total * 1.0);
		if (fraction > 1.0){
			fraction = 1.0;
		}
		progressbar.fraction = fraction;
	}
	
	public void finish(string message = "") {
		pulse_stop();
		progressbar.fraction = 1.0;
		
		lbl_msg.label = message;
		lbl_status.label = "";
		
		spinner.visible = false;
		
		gtk_do_events();
		auto_close_window();
	}

	private void auto_close_window() {
		tmr_close = Timeout.add(2000, ()=>{
			if (tmr_init > 0) {
				Source.remove(tmr_init);
				tmr_init = 0;
			}

			this.close();
			return false;
		});
	}
	
	public void sleep(int ms){
		Thread.usleep ((ulong) ms * 1000);
		gtk_do_events();
	}
}


