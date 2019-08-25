/*
 * Copyright (C) 2002-2019 by the Widelands Development Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

#include "editor/ui_menus/scenario_lua.h"

#include <boost/format.hpp>

#include "base/i18n.h"
#include "editor/editorinteractive.h"
#include "ui_basic/messagebox.h"

const std::string kUnnamedVariablePrefix = "variable_";
const std::string kUnnamedFunctionPrefix = "function_";

inline EditorInteractive& ScenarioLuaOptionsMenu::eia() {
	return dynamic_cast<EditorInteractive&>(*get_parent());
}

/**
 * Create all the buttons etc...
 */
ScenarioLuaOptionsMenu::ScenarioLuaOptionsMenu(EditorInteractive& parent,
                                       UI::UniqueWindow::Registry& registry)
   : UI::UniqueWindow(&parent, "scenario_lua", &registry, 700, 500, _("Scripting")),
     tabs_(this, UI::TabPanelStyle::kWuiLight) {
	set_center_panel(&tabs_);

	functions_box_.reset(new UI::Box(&tabs_, 0, 0, UI::Box::Vertical));
	tabs_.add("func", _("Functions"), functions_box_.get(), _("Write functions and scripts"));
	functions_buttonbox_.reset(new UI::Box(functions_box_.get(), 0, 0, UI::Box::Horizontal));
	functions_button_add_.reset(new UI::Button(functions_buttonbox_.get(), "add", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Add"), _("Add a new function")));
	functions_button_edit_.reset(new UI::Button(functions_buttonbox_.get(), "edit", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Rename"), _("Rename the current function")));
	functions_button_delete_.reset(new UI::Button(functions_buttonbox_.get(), "delete", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Delete"), _("Delete the current function")));
	functions_dropdown_.reset(new UI::Dropdown<std::string>(functions_box_.get(), "functions_dropdown",
			0, 0, get_inner_w(), 8, 30, _("Current function"), UI::DropdownType::kTextual,
			UI::PanelStyle::kWui, UI::ButtonStyle::kWuiSecondary));
	functions_autostart_.reset(new UI::Checkbox(functions_box_.get(), Vector2i(0, 0),
			_("Run as coroutine on scenario start"), _("Run this function as a coroutine when the scenario starts")));
	functions_lowerbox_.reset(new UI::Box(functions_box_.get(), 0, 0, UI::Box::Horizontal));
	functions_body_.reset(new UI::Listselect<std::string>(functions_lowerbox_.get(), 0, 0, 600, 400,
			UI::PanelStyle::kWui));
	functions_sidepanel_.reset(new UI::Box(functions_lowerbox_.get(), 0, 0, UI::Box::Vertical));

	update_functions(kMainFunction);
	functions_buttonbox_->add(functions_button_add_.get());
	functions_buttonbox_->add(functions_button_edit_.get());
	functions_buttonbox_->add(functions_button_delete_.get());
	functions_lowerbox_->add(functions_body_.get(), UI::Box::Resizing::kFullSize);
	functions_lowerbox_->add(functions_sidepanel_.get(), UI::Box::Resizing::kExpandBoth);
	functions_box_->add(functions_buttonbox_.get(), UI::Box::Resizing::kAlign, UI::Align::kCenter);
	functions_box_->add(functions_dropdown_.get(), UI::Box::Resizing::kFullSize);
	functions_box_->add(functions_autostart_.get(), UI::Box::Resizing::kFullSize);
	functions_box_->add(functions_lowerbox_.get(), UI::Box::Resizing::kExpandBoth);

	// NOCOM add sidepanel buttons

	variables_box_.reset(new UI::Box(&tabs_, 0, 0, UI::Box::Vertical));
	tabs_.add("vars", _("Variables"), variables_box_.get(), _("Declare and set global variables and constants"));
	variables_list_.reset(new UI::Table<uintptr_t>(variables_box_.get(), 0, 0, 600, 400, UI::PanelStyle::kWui));
	variables_buttonbox_.reset(new UI::Box(variables_box_.get(), 0, 0, UI::Box::Horizontal));
	variables_button_add_.reset(new UI::Button(variables_buttonbox_.get(), "add", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Add"), _("Add a new variable")));
	variables_button_edit_.reset(new UI::Button(variables_buttonbox_.get(), "edit", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Edit"), _("Edit the selected variable")));
	variables_button_delete_.reset(new UI::Button(variables_buttonbox_.get(), "delete", 0, 0, 200, 30,
			UI::ButtonStyle::kWuiSecondary, _("Delete"), _("Delete the selected variable")));
	variables_buttonbox_->add(variables_button_add_.get());
	variables_buttonbox_->add(variables_button_edit_.get());
	variables_buttonbox_->add(variables_button_delete_.get());
	variables_list_->add_column(400, _("Name"));
	variables_list_->add_column(200, _("Value"));

	update_variables();
	variables_box_->add(variables_list_.get(), UI::Box::Resizing::kFullSize);
	variables_box_->add(variables_buttonbox_.get(), UI::Box::Resizing::kAlign, UI::Align::kCenter);

	variables_button_add_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_add_variable, this));
	variables_button_edit_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_edit_variable, this));
	variables_button_delete_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_delete_variable, this));
	variables_list_->selected.connect(boost::bind(&ScenarioLuaOptionsMenu::update_variable_buttons, this));
	variables_list_->double_clicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_edit_variable, this));

	functions_button_add_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_add_function, this));
	functions_button_edit_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_edit_function, this));
	functions_button_delete_->sigclicked.connect(boost::bind(&ScenarioLuaOptionsMenu::clicked_delete_function, this));
	functions_autostart_->clickedto.connect(boost::bind(&ScenarioLuaOptionsMenu::toggle_autostart, this, _1));
	functions_dropdown_->selected.connect(boost::bind(&ScenarioLuaOptionsMenu::update_function_body, this));

	if (get_usedefaultpos()) {
		center_to_parent();
	}
}

void ScenarioLuaOptionsMenu::clicked_add_variable() {
	size_t i = 1;
	for (; eia().variables().find(kUnnamedVariablePrefix + std::to_string(i)) != eia().variables().end(); ++i);
	const std::string name = kUnnamedVariablePrefix + std::to_string(i);
	eia().variables().emplace(std::make_pair(name, Variable("nil", "nil")));
	update_variables(name);
}

void ScenarioLuaOptionsMenu::clicked_edit_variable() {
	// NOCOM show a dialog with a text field for the name and a dropdown for the value type and
	// an inputfield/spinner/checkbox for the value.
	// And make sure to apply the name change to all FunctionStatements!
	log("NOCOM: ScenarioLuaOptionsMenu::clicked_edit_variable: not yet implemented\n");
}

void ScenarioLuaOptionsMenu::clicked_delete_variable() {
	assert(variables_list_->has_selection());
	const std::string sel = variables_list_->get_selected_record().get_string(0);
	UI::WLMessageBox m(
			get_parent(), _("Delete Variable"),
			_("Are you sure you want to delete this variable? This action cannot be undone."),
			UI::WLMessageBox::MBoxType::kOkCancel);
	m.ok.connect([this, sel] {
		assert(eia().variables().find(sel) != eia().variables().end());
		eia().variables().erase(eia().variables().find(sel));
		update_variables();
	});
	m.run<UI::Panel::Returncodes>();
}

void ScenarioLuaOptionsMenu::clicked_add_function() {
	size_t i = 1;
	for (; eia().functions().find(kUnnamedFunctionPrefix + std::to_string(i)) != eia().functions().end(); ++i);
	const std::string name = kUnnamedFunctionPrefix + std::to_string(i);
	eia().functions().emplace(std::make_pair(name, Function(false)));
	update_functions(name);
}

void ScenarioLuaOptionsMenu::clicked_edit_function() {
	// NOCOM show a dialog with a text field for the name.
	// Make sure to apply the name change to all FunctionStatements that invoke this function!
	log("NOCOM: ScenarioLuaOptionsMenu::clicked_edit_function: not yet implemented\n");
}

void ScenarioLuaOptionsMenu::clicked_delete_function() {
	assert(functions_dropdown_->has_selection());
	const std::string sel = functions_dropdown_->get_selected();
	assert(sel != kMainFunction);
	UI::WLMessageBox m(
			get_parent(), _("Delete Function"),
			_("Are you sure you want to delete this function? This action cannot be undone."),
			UI::WLMessageBox::MBoxType::kOkCancel);
	m.ok.connect([this, sel] {
		assert(eia().functions().find(sel) != eia().functions().end());
		eia().functions().erase(eia().functions().find(sel));
		update_functions();
	});
	m.run<UI::Panel::Returncodes>();
}

void ScenarioLuaOptionsMenu::toggle_autostart(bool on) {
	assert(functions_dropdown_->has_selection());
	eia().functions().at(functions_dropdown_->get_selected()).autostart = on;
}

void ScenarioLuaOptionsMenu::update_variables(std::string sel) {
	if (sel.empty()) {
		sel = variables_list_->has_selection() ? variables_list_->get_selected_record().get_string(0) : "";
	}
	variables_list_->clear();
	size_t i = 0;
	for (const auto& pair : eia().variables()) {
		auto& entry = variables_list_->add(i++, pair.first == sel);
		entry.set_string(0, pair.first);
		entry.set_string(1, pair.second.value);
	}
	update_variable_buttons();
}

void ScenarioLuaOptionsMenu::update_variable_buttons() {
	const bool s = variables_list_->has_selection();
	variables_button_edit_->set_enabled(s);
	variables_button_delete_->set_enabled(s);
}

void ScenarioLuaOptionsMenu::update_functions(std::string sel) {
	if (sel.empty()) {
		sel = functions_dropdown_->has_selection() ? functions_dropdown_->get_selected() : "";
	}
	functions_dropdown_->clear();
	for (const auto& pair : eia().functions()) {
		functions_dropdown_->add(pair.first, pair.first, nullptr, pair.first == sel);
	}
	update_function_body();
}

void ScenarioLuaOptionsMenu::update_function_body() {
	functions_body_->clear();
	const bool sel = functions_dropdown_->has_selection();
	functions_autostart_->set_enabled(sel);
	functions_button_edit_->set_enabled(sel);
	functions_button_delete_->set_enabled(sel);
	// NOCOM enable/disable all sidepanel buttons
	if (sel) {
		const std::string& name = functions_dropdown_->get_selected();
		const Function& f = eia().functions().at(name);
		functions_autostart_->set_state(f.autostart);
		if (name == kMainFunction) {
			functions_autostart_->set_enabled(false);
			functions_button_edit_->set_enabled(false);
			functions_button_delete_->set_enabled(false);
		}
		// NOCOM add function definition to the listselect
	}
}

