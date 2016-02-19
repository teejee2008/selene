/*
 * MediaPlayerWindow.vala
 *
 * Copyright 2012 Tony George <teejee2008@gmail.com>
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

public class MediaPlayerWindow : Gtk.Window {
	private Gtk.Box vboxMain;
	private Gtk.DrawingArea canvas;
	private Gtk.Scale scalePos;
	private MediaPlayer player;
	private X.Window xid;

	private MediaFile fileToPlay;
	
	public MediaPlayerWindow(Gtk.Window parent, MediaFile _fileToPlay) {
		set_transient_for(parent);
		set_destroy_with_parent(true);
        set_skip_taskbar_hint(true);

		window_position = WindowPosition.CENTER_ON_PARENT;
		icon = get_app_icon(16);
		
		modal = true;
		deletable = true;
		resizable = true;
		
		player = new MediaPlayer();
		title = "";

		fileToPlay = _fileToPlay;

		// get content area
		vboxMain = new Gtk.Box(Orientation.VERTICAL,6); //get_content_area();
		vboxMain.set_size_request(600,600);
		add(vboxMain);
		
		canvas = new Gtk.DrawingArea();
		canvas.set_size_request(400,300);
		canvas.expand = true;
		vboxMain.pack_start (canvas, true, true, 0);

		scalePos = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 200, 1);
		scalePos.adjustment.value = 0;
		scalePos.has_origin = false;
		scalePos.value_pos = PositionType.RIGHT;
		//scalePos.set_size_request(scaleWidth,-1);
		scalePos.margin_bottom = 6;
		vboxMain.add(scalePos);

		scalePos.value_changed.connect (() => {
			player.Seek(scalePos.get_value());
		});
		
		scalePos.format_value.connect((val)=>{ return format_duration(1000); });

        this.canvas.realize.connect(() => {
			this.xid = (ulong)(((Gdk.X11.Window) this.canvas.get_window()).get_xid());
			log_msg("%u".printf((uint)this.xid));
			player.WindowID = (uint) this.xid;
			player.StartPlayer();
		});
		
		this.delete_event.connect(()=>{
			player.Exit();
			return false;
		});
	}

	public void Play(string file_path, int width, int height){
		this.resize(width,height);
		//player.Open(mFile, false, false, true);
	}

	public void Crop(int width, int height, int cropL, int cropR, int cropT, int cropB){
		this.resize(width - cropL - cropR, height - cropT - cropB);
		//player.Crop(width, height, cropL, cropR, cropT, cropB);
	}
	
}
