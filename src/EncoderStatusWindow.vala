/*
 * FileInfoWindow.vala
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

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class EncoderStatusWindow : Gtk.Dialog {

	private Gtk.Box vboxMain;
	private Gtk.Box vbox_actions;
	private Gtk.Button btnOk;
	private Gtk.Button btnRefesh;
	private Gtk.TreeView tv;
	private Gtk.ScrolledWindow sw;

	public EncoderStatusWindow (Gtk.Window parent) {
		title = _("Encoders");

		set_transient_for(parent);
		set_modal(true);
		
        window_position = WindowPosition.CENTER_ON_PARENT;
        destroy_with_parent = true;
        skip_taskbar_hint = true;
		deletable = true;
		resizable = false;
		icon = get_app_icon(16);

		// get content area
		vboxMain = get_content_area();
		vboxMain.set_size_request (500, 450);

		// get action area
		vbox_actions = (Box) get_action_area();

	    tv = new TreeView();
		tv.get_selection().mode = SelectionMode.SINGLE;
		tv.headers_visible = true;
		//tv.set_rules_hint (true);

		sw = new ScrolledWindow(null, null);
		sw.set_shadow_type (ShadowType.ETCHED_IN);
		sw.add (tv);
		sw.expand = true;
		vboxMain.add(sw);

		TreeViewColumn col_name = new TreeViewColumn();
		col_name.title = " " + _("Tool") + " ";
		col_name.resizable = true;
		
		CellRendererPixbuf cell_icon = new CellRendererPixbuf ();
		col_name.pack_start (cell_icon, false);
		col_name.set_attributes(cell_icon, "pixbuf", 3);
		
		CellRendererText cell_name = new CellRendererText ();
		col_name.pack_start (cell_name, false);
		col_name.set_attributes(cell_name, "text", 0);

		tv.append_column(col_name);
		
		TreeViewColumn col_desc = new TreeViewColumn();
		col_desc.title = " " + _("Description") + " ";
		tv.append_column(col_desc);

		CellRendererText cell_desc = new CellRendererText ();
		col_desc.pack_start (cell_desc, false);
		col_desc.set_attributes(cell_desc, "text", 1);

		TreeViewColumn col_status = new TreeViewColumn();
		col_status.title = " " + _("Status") + " ";
		tv.append_column(col_status);

		CellRendererText cell_status = new CellRendererText ();
		col_status.pack_start (cell_status, false);
		col_status.set_attributes(cell_status, "text", 2);

		tv_refresh();

		//btnRefesh
        btnRefesh = new Button.with_label("   " + _("Refresh") + "   ");
		vbox_actions.add(btnRefesh);
		btnRefesh.clicked.connect(()=>{
			gtk_set_busy(true,this);
			App.check_all_encoders();
			tv_refresh();
			gtk_set_busy(false,this);
		});

        //btnOk
        btnOk = (Button) add_button ("gtk-ok", Gtk.ResponseType.ACCEPT);
        btnOk.clicked.connect (() => {  destroy();  });

		show_all();
	}

	public void tv_refresh(){
		TreeStore store = new TreeStore (4, typeof (string), typeof (string), typeof (string), typeof(Gdk.Pixbuf));

		//status icons
		Gdk.Pixbuf pix_ok = null;
		Gdk.Pixbuf pix_missing = null;

		try{
			pix_ok = new Gdk.Pixbuf.from_file("/usr/share/selene/images/item-green.png");
			pix_missing  = new Gdk.Pixbuf.from_file("/usr/share/selene/images/item-red.png");
		}
        catch(Error e){
	        log_error (e.message);
	    }

		TreeIter iter;
		var list = new Gee.ArrayList<Encoder>();
		foreach (Encoder enc in App.Encoders.values){
			list.add(enc);
		}
		CompareDataFunc<Encoder> func = (a, b) => {
			return strcmp(a.Command,b.Command);
		};
		list.sort((owned)func);
		
		foreach (Encoder enc in list){
			store.append(out iter, null);
			store.set(iter, 0, enc.Command);
			store.set(iter, 1, enc.Name);
			store.set(iter, 2, enc.IsAvailable ? _("Found") : _("Missing"));
			store.set(iter, 3, enc.IsAvailable ? pix_ok : pix_missing);
		}
		
		/*foreach(string codec_name in new string[]{"libfdk_aac"}){
			store.append(out iter, null);
			store.set(iter, 0, "%s (FFmpeg)".printf(codec_name));
			if (App.FFmpegCodecs.has_key(codec_name)){
				var codec = App.FFmpegCodecs[codec_name];
				store.set(iter, 1, codec.Description);
				store.set(iter, 2, codec.EncodingSupported ? _("Found") : _("Missing"));
				store.set(iter, 3, codec.EncodingSupported ? pix_ok : pix_missing);
			}
			else{
				store.set(iter, 1, "");
				store.set(iter, 2, _("Missing"));
				store.set(iter, 3, pix_missing);
			}
		}*/

		tv.set_model (store);
	}
}
