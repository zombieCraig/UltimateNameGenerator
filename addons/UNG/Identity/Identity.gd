class_name Identity

const MALE: float = 1.0
const NON_BINARY: float = 0.5  # Used for gender-Nonconforming and gender-queer
const FEMALE: float = 0.0

enum GenderLabel {MALE, NON_BINARY, FEMALE}

const GENDER_CUTOFF_OFFSET: float = 0.05

static func generate_gender_value() -> float:
	var rng:= RandomNumberGenerator.new()
	rng.randomize()
	return rng.randf_range(GenderLabel.MALE, GenderLabel.FEMALE)

static func is_male(val) -> bool:
	return val > GenderLabel.NON_BINARY + GENDER_CUTOFF_OFFSET

static func is_female(val) -> bool:
	return val < GenderLabel.NON_BINARY - GENDER_CUTOFF_OFFSET and val >= 0.0

static func is_non_binary(val) -> bool:
	return val >= 0.0 and (!is_male(val) and !is_female(val))

static func gender_value_to_label(val) -> String:
	if is_male(val):
		return "male"
	elif is_female(val):
		return "female"
	else:
		return "non-binary"

# Them, him, her
static func pronoun(val) -> String:
	var pn := "them"
	if is_male(val):
		return "him"
	elif is_female(val):
		return "her"
	return pn

# They, he, she
static func pronoun_subj(val) -> String:
	var pn := "they"
	if is_male(val):
		return "he"
	elif is_female(val):
		return "she"
	return pn

# They are, he is, she is
static func pronoun_subj_are(val) -> String:
	var pn := "they are"
	if is_male(val):
		return "he is"
	elif is_female(val):
		return "she is"
	return pn

# They were, he was, she was
static func pronoun_subj_were(val) -> String:
	var pn := "they were"
	if is_male(val):
		return "he was"
	elif is_female(val):
		return "she was"
	return pn

# They are, he is, she is
static func pronoun_subj_have(val) -> String:
	var pn := "they have"
	if is_male(val):
		return "he has"
	elif is_female(val):
		return "she has"
	return pn

# Possessive pronouns:  Their, his, her
static func pronoun_possess(val) -> String:
	var pn := "their"
	if is_male(val):
		return "his"
	elif is_female(val):
		return "her"
	return pn
