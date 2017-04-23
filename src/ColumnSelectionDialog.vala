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

public class ColumnSelectionDialog : Gtk.Window {

	public ColumnSelectionDialog.with_parent(Window _window, TreeViewColumnManager _manager) {

		log_debug("ColumnSelectionDialog()");

		title = _("Select Columns");
		
		set_transient_for(_window);
		set_modal(true);
		set_skip_taskbar_hint(true);
		set_skip_pager_hint(true);
		window_position = WindowPosition.CENTER_ON_PARENT;

		set_transient_for(_window);
		set_modal(true);

		// get content area
		//var vbox_main = get_content_area();
		//vbox_main.set_size_request(300,300);

		var colbox = new ColumnSelectionBox(this, _manager);
		add(colbox);
		
        show_all();
	}
}


