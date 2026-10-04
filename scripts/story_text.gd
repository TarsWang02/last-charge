class_name StoryText
## All player-facing story text in one place (English in game; Chinese drafts in docs/story_text.md and
## docs/narrative_monologue_script.md). Shown by scripts/captions.gd. Edit wording here only.
## First person throughout: the old man asleep in the bedroom is "I"; I'm in my old tin robot.

## (The opening is a cutscene in room.gd now; it shows the time, then the monologue below.)
const OPENING := [
	["2:14 a.m.", 2.5],
]

## Small, low-contrast controls card - shown once, when the player first gets control.
const CONTROLS := "WASD  move     SPACE  jump     MOUSE  look     E  use (costs charge)"

## The inner monologue (docs/narrative_monologue_script.md): id -> line. Captions.say(id).
const MONOLOGUE := {
	"0-1": "...Where am I?",
	"0-2": "Hang on. That's my bed.",
	"0-3": "And that's... me.",
	"0-4": "Then who's this?",
	"0-5": "Who's that at my desk? ...At this hour?",
	"0-7": "...That robot. That's this. I'm in my old tin robot.",
	"0-8": "Whoa— struth!",
	"1-1": "My old toy box. Mum swore she'd chucked this out.",
	"1-2": "Don't like the dark down there. Never did.",
	"1-2b": "All aboard. Dad built that track.",
	"1-3": "Still scares the daylights out of me. Seventy years on.",
	"1-4": "Big Tom. Wouldn't sleep without him till I was nine.",
	"1-5": "Costs me a bit. Everything does, these days.",
	"1-6": "Here we go again—",
	"2-1": "Hang on... isn't that me?",
	"2-2": "Why am I so young? Can't be more than fifteen.",
	"2-3": "Struth. Black as pitch. Can't see a blessed thing.",
	"2-4": "Every bit of light costs me now.",
	"2-5": "My desk was always a maze. Mum reckoned I'd lose my own head in it.",
	"2-6": "Door's right down the far end. Course it is.",
	"2-7": "Mind the cracks. Always did fall through them.",
	"2-8": "Mum always said that rubber'd come in handy.",
	"2-9": "There. Good as a bridge.",
	"2-13": "The breaker. That's what's gone.",
	"2-14": "...Telly's still going, though.",
	"3-1": "There I am again.",
	"3-2": "Twenty-two. Hair down to my collar. Thought I was something.",
	"3-3": "Every game I ever owned. Never chucked one out.",
	"3-4": "Haven't played this since... well. Since.",
	"3-5": "Oi— what's— it's pulling me in—!",
	"3-13": "Got there in the end. Only took me sixty years.",
	"3-14": "...And there goes the telly.",
	"3-15": "My old time box.",
	"3-16": "My drawing. Me and the robot, beating the dragon.",
	"3-17": "Thought I'd be a hero. Ended up a farmer. Not a bad trade.",
}

## Mum's note on the desk, read with E (handwritten, on yellowed paper).
const MUM_NOTE := "Love —\n\nGone to help Mrs Kelly with the calving. Back soon.\n\nTea's in the oven. Finish your maths.\n\nP.S. Your robot's on the windowsill.\nStop leaving him out in the rain.\n\n— Mum x"

## Game.restore_memory(id) -> {title, body}. Title = the object, body = one or two quiet lines.
const MEMORIES := {
	"family_photo": {
		"title": "The family photo",
		"body": "Christmas, '53. Mum, Dad... and me,\nhanging on to that robot like it was gold.",
	},
	"mom_note": {
		"title": "Mum's note",
		"body": "\"Back soon.\" She always was.\nTill the one time she wasn't.",
	},
	"time_box": {
		"title": "My time box",
		"body": "",   # said aloud instead (3-16, 3-17)
	},
	"daughter_mug": {
		"title": "Lucy's mug",
		"body": "She painted it when she was five.\nStill rings the same. She doesn't ring as often.",
	},
}

## No ending text on purpose: the finale and the one-take ending (room.gd) are wordless.
