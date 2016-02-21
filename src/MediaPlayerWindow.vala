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
	private Gtk.Scale scaleVolume;
	private Gtk.Button btnPlay;
	private Gtk.Button btnMute;
	
	private MediaPlayer player;
	private MediaFile mFile;

	private uint tmr_status = 0;
	
	public MediaPlayerWindow(MediaFile _mFile) {
		//set_transient_for(parent);
		//set_destroy_with_parent(true);
        //set_skip_taskbar_hint(true);
		//window_position = WindowPosition.CENTER_ON_PARENT;
		
		icon = get_app_icon(16);
		modal = false;
		deletable = true;
		resizable = false;
		
		player = new MediaPlayer();
		title = "Selene Media Player";

		mFile = _mFile;

		// get content area
		vboxMain = new Gtk.Box(Orientation.VERTICAL,0);
		add(vboxMain);
		
		init_ui_player();

		init_ui_player_controls();

		this.delete_event.connect(()=>{
			player.Exit();
			return false;
		});

		set_play_icon();
		set_mute_icon();
	}

	public static void PlayFile(MediaFile mf){
		var win = new MediaPlayerWindow(mf);
		win.show_all();
		win.Play();
	}

	public void init_ui_player(){
		canvas = new Gtk.DrawingArea();
		canvas.expand = true;
		vboxMain.pack_start (canvas, true, true, 0);

		canvas.realize.connect(() => {
			player.WindowID = get_widget_xid(canvas);
			player.StartPlayer();
		});
	}

	public void init_ui_player_controls(){
		var hboxControls = new Gtk.Box(Orientation.HORIZONTAL, 6);
		hboxControls.margin = 6;
		vboxMain.add(hboxControls);

		//btnPlay
		btnPlay = new Gtk.Button();
		hboxControls.add(btnPlay);

		btnPlay.clicked.connect(() => {
			player.PauseToggle();
			set_play_icon();
		});

		//btnMute
		btnMute = new Gtk.Button();
		hboxControls.add(btnMute);

		btnMute.clicked.connect(() => {
			if (player.IsMuted){
				player.UnMute();
			}
			else{
				player.Mute();
			}
			set_mute_icon();
		});

		//scalePos
		scalePos = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1000, 1);
		scalePos.adjustment.value = 0;
		scalePos.has_origin = true;
		scalePos.value_pos = PositionType.BOTTOM;
		scalePos.hexpand = true;
		scalePos.set_size_request(300,-1);
		hboxControls.add(scalePos);

		scalePos_value_changed_connect();
		
		scalePos.format_value.connect((val)=>{
			return format_duration((long) (val * 1000)) + " / " + format_duration(mFile.Duration);
		});

		//scaleVolume
		scaleVolume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
		scaleVolume.adjustment.value = 70;
		scaleVolume.has_origin = true;
		scaleVolume.value_pos = PositionType.BOTTOM;
		scaleVolume.hexpand = false;
		scaleVolume.set_size_request(100,-1);
		hboxControls.add(scaleVolume);

		scaleVolume.value_changed.connect(()=>{
			player.SetVolume((int)scaleVolume.adjustment.value);
		});
	}

	private void scalePos_value_changed(){
		player.Seek(scalePos.get_value());
	}
	
	private void scalePos_value_changed_connect(){
		scalePos.value_changed.connect(scalePos_value_changed);
	}

	private void scalePos_value_changed_disconnect(){
		scalePos.value_changed.disconnect(scalePos_value_changed);
	}
	
	private void set_play_icon(){
		if (player.IsPaused){
			btnPlay.set_tooltip_text (_("Play"));
			btnPlay.image = get_shared_icon("", "media-playback-start.png", 24);
		}
		else{
			btnPlay.set_tooltip_text (_("Pause"));
			btnPlay.image = get_shared_icon("", "media-playback-pause.png", 24);
		}
		gtk_do_events();
	}
	
	private void set_mute_icon(){
		if (player.IsMuted){
			btnMute.set_tooltip_text (_("Unmute"));
			btnMute.image = get_shared_icon("", "audio-muted.svg", 24);
		}
		else{
			btnMute.set_tooltip_text (_("Mute"));
			btnMute.image = get_shared_icon("", "audio-high.svg", 24);
		}
		gtk_do_events();
	}

	protected void Play(){
		canvas.set_size_request(mFile.SourceWidth, mFile.SourceHeight);
		scalePos.adjustment.upper = (mFile.Duration/1000);
		player.Open(mFile, false, false, true);
		title = mFile.Name + " - Selene";
		
		status_timer_start();
	}

	private void status_timer_start(){
		status_timer_stop();

		tmr_status = Timeout.add(1000, status_timeout);
	}

	private void status_timer_stop(){
		if (tmr_status > 0) {
			Source.remove(tmr_status);
			tmr_status = 0;
		}
	}
	
	private bool status_timeout(){
		status_timer_stop();

		scalePos_value_changed_disconnect();
		scalePos.adjustment.value = (int) player.Position;
		scalePos_value_changed_connect();

		set_play_icon();
		set_mute_icon();

		gtk_do_events();

		status_timer_start();
		return true;
	}
}
