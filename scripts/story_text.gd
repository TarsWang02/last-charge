class_name StoryText
## All player-facing story text in one place (English in game; Chinese drafts in docs/story_text.md).
## Shown by scripts/captions.gd. Edit wording here only - no logic depends on the exact strings.

## Fades in over the bedroom before the player gets control. [line, seconds on screen]
const OPENING := [
	["The power went out at 2:14 a.m.", 3.5],
	["Everyone in the house was asleep.\nAlmost everyone.", 4.0],
]

## Small, low-contrast controls card - shown once, after the opening.
const CONTROLS := "WASD  move     SPACE  jump     MOUSE  look     E  use (costs charge)"

## Game.restore_memory(id) -> {title, body}. Title = the object, body = one or two quiet lines.
## The robot is "you": it is the toy the boy holds in the family photo.
const MEMORIES := {
	"family_photo": {
		"title": "The family photo",
		"body": "Christmas, 1979.\nHe wouldn't put you down all day.",
	},
	"mom_note": {
		"title": "Mum's note",
		"body": "\"Back soon. Finish your maths.\"\nHe never did finish the maths.",
	},
	"time_box": {
		"title": "The time box",
		"body": "A crayon knight, a dragon, and a little yellow robot.\nUnderneath, in big letters: MY BEST FRIEND.",
	},
	"daughter_mug": {
		"title": "Lucy's mug",
		"body": "She painted it when she was five.\nIt still rings the same.",
	},
	# stop 5 (windowsill / armchair / radio) - not wired yet; use Game.restore_memory("radio")
	"radio": {
		"title": "The old radio",
		"body": "Sunday mornings, their song.\nHe still turns it on. He just doesn't turn it up.",
	},
}

## Stop 6 - the breaker box. Lines while holding E (shown as the charge drains, by progress 0..1).
const BREAKER_HOLD := [
	[0.0, "Hold on."],
	[0.5, "Just a little more."],
	[0.9, "There."],
]

## After the lights come back on. [line, seconds on screen]
const ENDING := [
	["The lights came back on at 3:02 a.m.", 3.5],
	["The fridge hummed. The clock on the oven blinked 12:00.", 4.0],
	["In the morning, he found you by the breaker box.\nOut of charge.", 4.5],
	["He put you back on the nightstand, next to the photo.", 4.5],
	["LAST CHARGE", 3.0],
	["Thank you for playing.", 3.0],
]
