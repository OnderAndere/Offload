# Searching

**On Android** there is a magnifying glass (**Search**) at the top right, next to the gear. It opens
the search screen, with the cursor straight in the search field ("Search items and people").

**On Windows** this search field is always above the list of Today or the Inbox; the shortcut
**Ctrl+F** jumps to it, even while you are typing somewhere else, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md). As long as you have
typed something, the results replace the list; **Esc** empties the field and goes back to the list.

## Searching

While you type, the results appear straight away, best match first. Items and people are mixed in
one list, each with its own icon: an item has an icon with lines of text, a person an icon with the
outline of a head and shoulders.

- An **item** shows its title, or otherwise the text as you captured it, and the moment you
  captured it; if the item has a project, that is shown below it, see [Projects](projects.md).
- A **person** shows the name and the first line of the note.

If you tap an **item**, it opens, see [Viewing and editing an item](item-detail.md). If you tap a
**person**, that person's screen opens, see [People](people.md). Item cards also show the chips for
who asked for it and who it is waiting for.

## What is searched

- For an item: the title, the text and the note.
- For a person: the name, the nicknames, the note, the job title, the organisation, the phone
  numbers (even if you only type the digits, and also on the international form: `+316…` finds
  `06-…`, read according to the **Country for phone numbers** in [Settings](settings.md)), the
  email addresses and the own labels of contact details.

A tag or a name that you typed with a sign in your text can be found by the word in it:
`#renovation` is found by searching for "renovation", `@Jan` by searching for "jan". If a person Jan
was created through `@Jan`, you can simply find them as a person too.

## How searching works

- Capital letters and accents do not matter: "cafe" also finds "café".
- The start of a word is enough: "inspec" finds "inspection", but "tion" finds nothing — it has to
  be the start of the word.
- If you type several words, they must all appear somewhere.
- A match in a title or name ranks higher than a match in the text or note.

You never see an item in the trash in the search results. An item you just captured may take a
moment before it can be found: the search is updated in the background after saving.

Everything stays on your device: searching is done entirely locally, and the search index is, like
the rest of your data, stored encrypted on disk.

## When you have not typed anything yet

As long as the search field is empty, the screen explains that the start of a word is enough. If
Offload finds nothing for what you typed, you see "Nothing found for “…”". With the cross (✕) next
to the search field you empty the field again.

## At the first start after this update

At the first start after this update, Offload puts your existing items and people into the search
index in the background; you do not have to do anything for that.
