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

public class FileInfoWindow : Gtk.Dialog {

	private Box vbox_main;
	private Button btn_ok;
	public MediaFile file;
	private TreeView tv_info;
	private ScrolledWindow sw_info;

	public FileInfoWindow (MediaFile _file) {
		title = _("Properties");
		set_default_size (700, 500);

        window_position = WindowPosition.CENTER_ON_PARENT;
        destroy_with_parent = true;
        skip_taskbar_hint = true;
		modal = true;
		deletable = false;
		icon = get_app_icon(16);

		//save reference
		file = _file;

		if (file.InfoTextFormatted.length == 0){
			file.query_mediainfo_formatted();
		}
		
		// get content area
		vbox_main = get_content_area();
		vbox_main.margin = 3;

		//tv_info
		tv_info = new TreeView();
		tv_info.get_selection().mode = SelectionMode.MULTIPLE;
		tv_info.headers_visible = false;
		tv_info.insert_column_with_attributes (-1, _("Key"), new CellRendererText(), "text", 0);
		tv_info.insert_column_with_attributes (-1, _("Value"), new CellRendererText(), "text", 1);
		
		sw_info = new ScrolledWindow(tv_info.get_hadjustment(), tv_info.get_vadjustment());
		sw_info.set_shadow_type (ShadowType.ETCHED_IN);
		sw_info.add (tv_info);
		sw_info.set_size_request (-1, 200);
		vbox_main.pack_start (sw_info, true, true, 0);

		var store = new TreeStore (2, typeof (string), typeof (string));

		TreeIter iter0;
		TreeIter iter1;
		int index = -1;
		store.append (out iter0, null);
		//store.remove (ref iter0);

		foreach (string line in file.InfoTextFormatted.split ("\n")){
			if (line.strip() == "") { continue; }

			index = line.index_of (":");

			if (index == -1){
				store.append (out iter0, null);
				store.set (iter0, 0, line.strip());
			}
			else{
				store.append (out iter1, iter0);
				store.set (iter1, 0, line[0:index-1].strip());
				store.set (iter1, 1, line[index+1:line.length].strip());
			}
		}
		tv_info.set_model (store);
		tv_info.expand_all();

        // btn_ok
        btn_ok = (Button) add_button ("gtk-ok", Gtk.ResponseType.ACCEPT);
        btn_ok.clicked.connect (() => {  destroy();  });
	}
}
