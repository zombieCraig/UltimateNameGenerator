tool
class_name VerbalIDHuman
extends VerbalID

# Features
# * Supports easy name management and generation
# * Generates multi-culteral names
# * Can prefer only first/last names
# * Can prefer to use a middle name instead of first name
# * Can use acryonyms for their name like JT for their shortname
# * Pronoun helper functions for grammar strings
# * Shortnames/Alternative names, ie: Richard, Rich, Dick, Bill
# * Gender Identity Management
#    * Male/Female/Non-Binary
# * Marry - Take last names, combine last names, move to middle names
# * Divoice - Remove last names, set dead_last_names
# * Nicknames can be added to first, last or to replace the shortname
# * Optional nickname generator included, leans towards aliteration
# * Titles, prefix & suffix for names.  get_title_name will assign Mr/Miss/Mrs/M/Ind
# * Complex Histories
#    * Gender Transitioning
#        * Transitioning names
#        * Dead names
#    * Age based marriage / divorce generation
# * Easy to edit external json names database
# * Builtin load/save function for saving and restoring info


const NAME_DATA_FILE = "res://addons/UNG/Identity/names.dat"

export(String, "None", "Male", "Female", "Non-Binary") var gender_override: String setget set_gender_override, get_gender_override
var birth_first_name: String
var middle_names: Array
var birth_middle_names: Array # Middle names assigned at birth
var birth_last_name: String
var prefix: String setget set_prefix, get_prefix
var suffix: String setget set_suffix, get_suffix

var transition_name: String
var dead_name: String
var dead_last_names: Array
var first_name: String setget set_first_name, get_first_name
var last_name: String setget set_last_name, get_last_name
var short_form_name: String # Set by engine normally (_generate_short_form_name
# Should only have 1 nickname like this
var first_name_nickname: String setget set_first_name_nickname, get_first_name_nickname
var last_name_nickname: String setget set_last_name_nickname, get_last_name_nickname
var nickname: String setget set_nickname, get_nickname

var uses_first_name := true
var uses_last_name := true
var uses_middle_name := false
var has_transitioned := false
var is_transitioning := false
var is_married := false
var has_divorced := false
var married_count := 0
export var age_in_years := -1 setget set_age_in_years, get_age_in_years
export var history_enabled := false setget set_history_enabled, get_history_enabled
export var generate_nicknames := false setget set_generate_nicknames, get_generate_nicknames

# History settings
var percentage_birth_middle_name = 0.5
var percentage_transitioned = 0.04
var percentage_non_binary_transitioning = 0.2
var percentage_prefers_lastname_only = 0.05
var percentage_prefers_firstname_only = 0.1
var percentage_prefers_middle_name = 0.04
var percentage_of_marriage = 0.5
var percentage_uses_nickname = 0.1
var minimum_age_of_transitioning: int = 13
var minimum_age_of_marrying: int = 16

var _perferred_middle_name: String
var _age_of_last_married = -1

var _fname_general = []

var _fname_femalish = []

var _fname_maleish = []

var _last_names = []

var _common_abbr = {}

# https://en.wiktionary.org/wiki/Appendix:English_given_names
var _short_forms = {}

# Typically adjectives
var _firstname_nicks = []

# Often nouns
var _lastname_nicks = []

# Nick could replace the name
var _nicknames = []

# FIXME: Not sure why this doesn't work
func _get_property_list():
	var properties = []
	properties.append({
			name = "Advanced %",
			type = TYPE_NIL,
			hint_string = "percentage_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	properties.append({
		name = "percentage_birth_middle_name",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_transitioned",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_non_binary_transitioning",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_prefers_lastname_only",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_prefers_firstname_only",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_prefers_middle_name",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_of_marriage",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
		name = "percentage_uses_nickname",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_EXP_RANGE,
		hint_string = "0.0,1.0,0.01",
	})
	properties.append({
			name = "Minimum Age",
			type = TYPE_NIL,
			hint_string = "minimum_age_of_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	properties.append({
		name = "minimum_age_of_transitioning",
		type = TYPE_INT,
		hint = PROPERTY_HINT_LENGTH,
	})
	properties.append({
		name = "minimum_age_of_marrying",
		type = TYPE_INT,
		hint = PROPERTY_HINT_LENGTH,
	})
	return properties

func _init() -> void:
	load_name_data()
	set_gender_value(Identity.generate_gender_value())
	generate_birth_name()

func load_name_data() -> void:
	var file := File.new()
	if file.file_exists(NAME_DATA_FILE):
		var name_data_str := ""
		var err := file.open(NAME_DATA_FILE, File.READ)
		if err == OK:
			name_data_str = file.get_as_text()
			file.close()
			var res := JSON.parse(name_data_str)
			if typeof(res.result) == TYPE_DICTIONARY:
				var d : Dictionary = res.result
				_fname_general = d["fname_general"]
				_fname_maleish = d["fname_maleish"]
				_fname_femalish = d["fname_femalish"]
				_last_names = d["last_names"]
				_common_abbr = d["common_abbr"]
				_short_forms = d["short_forms"]
				_firstname_nicks = d["firstname_nicks"]
				_lastname_nicks = d["lastname_nicks"]
				_nicknames = d["nicknames"]
			else:
				print_debug("Error parsing names database")
		else:
			print_debug("Couldn't open file: ", err)
	else:
		print_debug("Couldn't load names data")

# Meant to be called via the inspector.  Will force a recreate of the birthname
func set_gender_override(gender: String) -> void:
	_reset_birth_name()
	reset_history()
	match gender:
		"Male":
			gender_value = Identity.MALE
		"Female":
			gender_value = Identity.FEMALE
		"Non-Binary":
			gender_value = Identity.NON_BINARY
	gender_value = -1.0
	generate_birth_name()
	

func get_gender_override() -> String:
	return gender_override

func generate_birth_name() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var fname_pool = _fname_general.duplicate()
	if Identity.is_male(gender_value):
		fname_pool += _fname_maleish.duplicate()
	elif Identity.is_female(gender_value):
		fname_pool += _fname_femalish.duplicate()
	
	birth_first_name = fname_pool[rng.randi_range(0, fname_pool.size() - 1)]
	if rng.randf_range(0, 1.0) < percentage_birth_middle_name:
		birth_middle_names.push_back(fname_pool[rng.randi_range(0, fname_pool.size() - 1)])
	birth_last_name = _last_names[rng.randi_range(0, _last_names.size() - 1)]
	# Check for names that are too similar
	if birth_first_name == birth_last_name:
		generate_birth_name()
	
	# middle_names is used as the main container after birth
	if birth_middle_names.size() > 0:
		middle_names = birth_middle_names.duplicate()
		
	# Check and generates common abbreviations like JT
	_generate_name_abbreviation(rng)
	# Check for short name usage
	_generate_short_form_name(rng)

func _reset_birth_name() -> void:
	birth_first_name = ""
	birth_middle_names.clear()
	birth_last_name = ""
	nickname = ""
	short_form_name = ""

func set_age_in_years(years: int) -> void:
	age_in_years = years
	if history_enabled:
		reset_history()
		set_history_enabled(true)

func get_age_in_years() -> int:
	return age_in_years

func set_generate_nicknames(b: bool) -> void:
	generate_nicknames = b

func get_generate_nicknames() -> bool:
	return generate_nicknames

func set_history_enabled(b: bool) -> void:
	history_enabled = b
	if history_enabled:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		
		# Transitioning/ed genders
		if age_in_years < 0 or age_in_years > minimum_age_of_transitioning:
			if rng.randf_range(0, 1.0) < percentage_transitioned:
				set_first_name(_generate_transition_name())
				has_transitioned = true
			elif Identity.is_non_binary(gender_value):
				if rng.randf_range(0, 1.0) < percentage_non_binary_transitioning:
					set_transition_name(_generate_transition_name())
					is_transitioning = true
		
		# Marriage checks
		# Refence points
		# Marriage % by years https://flowingdata.com/2016/03/03/marrying-age/
		# Divorce rates by age https://time.com/4358792/woman-age-married-how-long/
		if age_in_years < 0 or age_in_years > minimum_age_of_marrying:
			if age_in_years > minimum_age_of_marrying:
				var marriage_chance : float = 0.01
				var slope: float = 0.014
				for age in range(minimum_age_of_marrying, age_in_years):
					if marriage_chance < 0.0:
						break
					if is_married:
						# Divorce odds increase for (age<23 & married 3-7)  55+ <2  
						if _age_of_last_married < 24 and (age - _age_of_last_married > 2 or age - _age_of_last_married < 8):
							if rng.randf_range(0.0, 1.0) <= 0.30: 
								divorce()
						elif _age_of_last_married > 54 and _age_of_last_married < 3:
							if rng.randi_range(0, 1) == 0: # 50% of divoice :(
								divorce()
						else:
							if rng.randf_range(0.0, 1.0) <= 0.01:
								divorce()
					elif rng.randf_range(0.0, 1.0) < marriage_chance:
						marry(_last_names[rng.randi_range(0, _last_names.size() - 1)])
						_age_of_last_married = age
					marriage_chance += slope
					if age == 28: # peak
						slope = -0.009
			if age_in_years < 0 and rng.randf_range(0, 1.0) < percentage_of_marriage:
				marry(_last_names[rng.randi_range(0, _last_names.size() - 1)])
		
		# Check if set should generate nicknames
		if generate_nicknames:
			if rng.randf_range(0, 1.0) < percentage_uses_nickname:
				match rng.randi_range(0, 2):
					0:
						_generate_first_name_nicknames(rng)
					1: # If already using a nickname such as JR, ignore 
						if nickname.length() == 0:
							_generate_last_name_nicknames(rng)
					2:  # If already using a nickname such as JR, ignore 
						if nickname.length() == 0:
							_generate_nicknames(rng)
		
		# Should be one of the last checks
		if rng.randf_range(0, 1.0) < percentage_prefers_lastname_only and get_first_name().length() > 0:
			uses_first_name = false
		elif rng.randf_range(0, 1.0) < percentage_prefers_firstname_only and get_last_name().length() > 0:
			uses_last_name = false
		elif rng.randf_range(0, 1.0) < percentage_prefers_middle_name and get_middle_names().length() > 0:
			uses_middle_name = true
			_perferred_middle_name = middle_names[rng.randi_range(0, middle_names.size() - 1)]
	else:
		reset_history()

func reset_history() -> void:
	first_name = ""
	last_name = ""
	middle_names = birth_middle_names.duplicate()
	dead_last_names.clear()
	dead_name = ""
	_age_of_last_married = -1
	uses_first_name = true
	uses_last_name = true
	uses_middle_name = false
	has_transitioned = false
	is_transitioning = false
	is_married = false
	has_divorced = false
	married_count = 0

func get_history_enabled() -> bool:
	return history_enabled

func set_transition_name(new_name) -> void:
	if new_name != birth_first_name:
		transition_name = new_name

func set_first_name(new_name) -> void:
	if new_name != birth_first_name:
		first_name = new_name
		dead_name = birth_first_name
		if transition_name.length() > 0:
			if new_name == transition_name:
				transition_name = ""

func get_first_name() -> String:
	if short_form_name.length() > 0:
		return short_form_name
	elif first_name.length() > 0:
		return first_name
	elif transition_name.length() > 0:
		return transition_name
	return birth_first_name

func set_last_name(new_name) -> void:
	if new_name != birth_last_name:
		last_name = new_name

func get_last_name() -> String:
	if last_name.length() > 0:
		return last_name
	return birth_last_name

func get_middle_names() -> String:
	if middle_names.size() > 0:
		return PoolStringArray(middle_names).join(" ")
	return ""

func _name_append(base: String, n: String) -> String:
	if n.length() > 0:
		if base.length() > 0:
			base += " "
		base += n
	return base

func get_birth_name() -> String:
	var birth_name := ""
	birth_name = _name_append(birth_name, birth_first_name)
	birth_name = _name_append(birth_name, PoolStringArray(birth_middle_names).join(" "))
	birth_name = _name_append(birth_name, birth_last_name)
	if birth_name.length() == 0:
		birth_name = "Unknown"
	return birth_name

# Generally first, last name and nicknames minus pre/suffix/titles
func get_name() -> String:
	var my_name := ""
	# Middle name preferrence overrides first name
	if uses_middle_name:
		if get_first_name_nickname().length() > 0:
			my_name = _name_append(my_name, get_first_name_nickname())
		my_name = _name_append(my_name, _perferred_middle_name)
	elif uses_first_name:
		if get_first_name_nickname().length() > 0:
			my_name = _name_append(my_name, get_first_name_nickname())
		my_name = _name_append(my_name, get_first_name())
	if get_nickname().length() > 0:
		my_name = _name_append(my_name, "\"" + get_nickname() + "\"")
	if uses_last_name:
		if get_last_name_nickname().length() > 0:
			my_name = _name_append(my_name, get_last_name_nickname())
		my_name = _name_append(my_name, get_last_name())
	if my_name.length() == 0:
		my_name = "Unknown"
	return my_name

# Includes sufix and titles but not nicknames
func get_fullname() -> String:
	var fullname := ""
	fullname = _name_append(fullname, prefix)
	fullname = _name_append(fullname, get_first_name())
	fullname = _name_append(fullname, get_middle_names())
	fullname = _name_append(fullname, get_last_name())
	fullname = _name_append(fullname, suffix)
	return fullname

# Typically just first name or nickname.  shortname aka "Goes by"
func get_shortname() -> String:
	var shortname := ""

	if get_nickname().length() > 0:
		shortname = _name_append(shortname, get_nickname())
	elif uses_middle_name:
		if get_first_name_nickname().length() > 0:
			shortname = _name_append(shortname, get_first_name_nickname())
		shortname = _name_append(shortname, _perferred_middle_name)
	elif uses_first_name:
		if get_first_name_nickname().length() > 0:
			shortname = _name_append(shortname, get_first_name_nickname())
		shortname = _name_append(shortname, get_first_name())
	elif uses_last_name:
		if get_last_name().length() > 0:
			shortname = _name_append(shortname, get_last_name_nickname())
		shortname = _name_append(shortname, get_last_name())
	else:
		shortname = "Unknown"
	return shortname

func set_first_name_nickname(nick: String) -> void:
	first_name_nickname = nick

func get_first_name_nickname() -> String:
	return first_name_nickname

func set_last_name_nickname(nick: String) -> void:
	last_name_nickname = nick

func get_last_name_nickname() -> String:
	return last_name_nickname

func set_nickname(nick: String) -> void:
	nickname = nick

func get_nickname() -> String:
	return nickname

func get_prefix() -> String:
	return prefix

func set_prefix(p: String) -> void:
	prefix = p

func get_suffix() -> String:
	return suffix

func set_suffix(s: String) -> void:
	suffix = s

func get_title_name() -> String:
	var lname := " " + get_last_name()
	if get_suffix().length() > 0:
		lname += " " + suffix
	if prefix.length() > 0:
		return prefix + lname
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if Identity.is_male(gender_value):
		return "Mr." + lname
	elif Identity.is_female(gender_value):
		if is_married:
			if birth_last_name == get_last_name():
				return "Mrs." + lname
			else:
				return "Ms." + lname
		else:
			if age_in_years > 17:
				if prefix.length() == 0:
					if rng.randi_range(0, 1) == 0:
						prefix = "Ms."
					else:
						prefix = "Miss"
					return prefix + lname
	# At this point they are gender neutral
	if rng.randi_range(0, 1) == 0:
		prefix = "Ind"
	else:
		prefix = "M"
	return prefix + lname

# Replacement first names for gender transitioning
func _generate_transition_name() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	if Identity.is_male(gender_value):
		gender_value = rng.randf_range(Identity.FEMALE, Identity.NON_BINARY + Identity.GENDER_CUTOFF_OFFSET)
	elif Identity.is_female(gender_value):
		gender_value = rng.randf_range(Identity.NON_BINARY - Identity.GENDER_CUTOFF_OFFSET, Identity.MALE)
	else:
		if rng.randi_range(0, 1) == 0:
			gender_value = rng.randf_range(Identity.NON_BINARY + Identity.GENDER_CUTOFF_OFFSET + 1, Identity.MALE)
		else:
			gender_value = rng.randf_range(Identity.FEMALE, Identity.NON_BINARY - Identity.GENDER_CUTOFF_OFFSET - 1)
	var fname_pool = _fname_general.duplicate()
	if Identity.is_male(gender_value):
		fname_pool += _fname_maleish.duplicate()
	elif Identity.is_female(gender_value):
		fname_pool += _fname_femalish.duplicate()
	return fname_pool[rng.randi_range(0, fname_pool.size() - 1)]

func marry(partners_last_name: String) -> void:
	if is_married:
		divorce()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	is_married = true
	married_count += 1
	match rng.randi_range(0, 3):
		0: # Takes last name
			set_last_name(partners_last_name)
		1: # Takes last name, birth last name to middle name
			set_last_name(partners_last_name)
			middle_names.push_back(birth_last_name)
		2: # Combines last name
			if rng.randi_range(0, 1) == 0:
				set_last_name(partners_last_name + " " + birth_last_name)
			else:
				set_last_name(partners_last_name + "-" + birth_last_name)

func divorce() -> void:
	if not is_married:
		return
	has_divorced = true
	is_married = false
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# 50% chance they keep the last name
	if rng.randi_range(0, 1) == 0:
		dead_last_names.push_back(last_name)
		set_last_name(birth_last_name)
		if middle_names.has(birth_last_name):
			middle_names.erase(birth_last_name)

# Helper function to return possive shortname
func get_possessive_name() -> String:
	var n := get_shortname()
	if n.ends_with("s"):
		n += "'"
	else:
		n += "'s"
	return n

# It is possible that a name may have a common abbreviation that will be used for a nickname
func _generate_name_abbreviation(rng: RandomNumberGenerator) -> void:
	var nick: String = get_first_name()[0] + get_last_name()[0]
	if _common_abbr.has(nick):
		if rng.randi_range(0, 3) == 0:
			set_nickname(nick.to_upper())

# Short form names: ie: Richard => Rich
func _generate_short_form_name(rng: RandomNumberGenerator) -> void:
	if _short_forms.has(get_first_name()):
		var names : Array = _short_forms[get_first_name()]
		if rng.randi_range(0, 2) == 0:
			short_form_name = names[rng.randi_range(0, names.size() - 1)]

func _generate_first_name_nicknames(rng: RandomNumberGenerator) -> void:
	# Increase chance of alliteration
	var fnicks : Array = _firstname_nicks.duplicate()
	for nick in _firstname_nicks:
		if get_first_name().length() > 0:
			if get_first_name()[0] == nick[0]:
				fnicks.append(nick)
	first_name_nickname = fnicks[rng.randi_range(0, fnicks.size() - 1)]

func _generate_last_name_nicknames(rng: RandomNumberGenerator) -> void:
	# Increase chance of alliteration
	var lnicks : Array = _lastname_nicks.duplicate()
	for nick in _lastname_nicks:
		if get_last_name().length() > 0:
			if get_last_name()[0] == nick[0]:
				lnicks.append(nick)
	last_name_nickname = lnicks[rng.randi_range(0, lnicks.size() - 1)]

func _generate_nicknames(rng: RandomNumberGenerator) -> void:
	nickname = _nicknames[rng.randi_range(0, _nicknames.size() - 1)]

# Returns this objects key info as a Dictionary that can be loaded back via load()
func save() -> Dictionary:
	var data = {}
	data["birth_first_name"] = birth_first_name
	data["middle_names"] = middle_names
	data["birth_last_name"] = birth_last_name
	data["prefix"] = prefix
	data["suffix"] = suffix
	data["transition_name"] = transition_name
	data["dead_name"] = dead_name
	data["dead_last_names"] = dead_last_names
	data["first_name"] = first_name
	data["last_name"] = last_name
	data["short_form_name"] = short_form_name
	data["first_name_nickname"] = first_name_nickname
	data["last_name_nickname"] = last_name_nickname
	data["nickname"] = nickname
	data["uses_first_name"] = uses_first_name
	data["uses_last_name"] = uses_last_name
	data["uses_middle_name"] = uses_middle_name
	data["has_transitioned"] = has_transitioned
	data["is_transitioning"] = is_transitioning
	data["is_married"] = is_married
	data["has_divorced"] = has_divorced
	data["married_count"] = married_count
	data["age_in_years"] = age_in_years
	return data

# loads data into object based on an expected Dictionary from save()
func load(data: Dictionary) -> void:
	birth_first_name = data["birth_first_name"]
	middle_names = data["middle_names"]
	birth_last_name = data["birth_last_name"] 
	prefix = data["prefix"]
	suffix = data["suffix"] 
	transition_name = data["transition_name"]
	dead_name = data["dead_name"] 
	dead_last_names = data["dead_last_names"]
	first_name = data["first_name"]
	last_name = data["last_name"]
	short_form_name = data["short_form_name"]
	first_name_nickname = data["first_name_nickname"]
	last_name_nickname = data["last_name_nickname"]
	nickname = data["nickname"]
	uses_first_name = data["uses_first_name"]
	uses_last_name = data["uses_last_name"]
	uses_middle_name = data["uses_middle_name"]
	has_transitioned = data["has_transitioned"]
	is_transitioning = data["is_transitioning"]
	is_married = data["is_married"]
	has_divorced = data["has_divorced"]
	married_count = data["married_count"]
	age_in_years = data["age_in_years"]

# Debug function to describe an identity
func describe() -> String:
	var n := ""
	var possess: String = Identity.pronoun_possess(gender_value)
	n += possess.capitalize() + " name is " + get_name() + ".\n"
	if get_name() != get_shortname():
		n += Identity.pronoun_subj_are(gender_value).capitalize() + " referred to as " + get_shortname() + ".\n"
	if get_name() != get_fullname():
		n += possess.capitalize() + " full legal name is " + get_fullname() + ".\n"
	if married_count > 0:
		n += Identity.pronoun_subj_have(gender_value).capitalize() + " been married " + str(married_count)
		if married_count > 1:
			n += " times.\n"
		else:
			n += " time.\n"
	if get_last_name() != birth_last_name:
		n += "Before marriage " + possess + " last name was " + birth_last_name + ".\n"
	if is_transitioning:
		n += Identity.pronoun_subj_are(gender_value).capitalize() + " currently gender transitioning.\n"
	elif has_transitioned:
		n += Identity.pronoun_subj_have(gender_value).capitalize() + " transitioned from their birth gender.\n"
	if get_birth_name() != get_fullname():
		n += possess.capitalize() + " original birth name was " + get_birth_name() + ".\n"
	return n

