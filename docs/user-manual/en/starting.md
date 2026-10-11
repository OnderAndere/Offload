# Starting Offload

Offload keeps its data encrypted on your device. When it starts, the app opens that encrypted
data. This is usually very fast; for a moment you see a loading indicator. Once that has
succeeded, Offload opens straight on **Today**, see [Today](today.md). From there you go to the
**Inbox**, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md).

If you start Offload for the first time, the app automatically creates a key and an empty
encrypted database.

## Windows: one instance

On Windows, Offload runs only once at a time. If you start the app again — for example from the
start menu, while Offload is already open — no second window opens. Instead, Offload brings the
window that is already open to the front, even if it was minimised at that moment or hidden in
the system tray.

## Windows: closing the window

If you close the Offload window with the cross, Offload does not stop: the window disappears
to the system tray (the area with small icons next to the clock) and Offload keeps running in
the background, so that the hotkey **Win+Shift+B** keeps working, see
[Capturing something](capturing.md). If you click the icon in the system tray (or select it
with the keyboard), the window comes back.

If you really want to close Offload, use **Quit** in the menu of the system tray icon (right
mouse button, or the menu key of your keyboard).

During startup, or on the explanation screen for a startup error below, the cross does
really close Offload: the system tray icon is not yet ready then to bring the window back.

## If the data cannot be opened

If opening fails once, Offload does not start, but you see an explanation screen with only the
**Try again** button and technical details at the bottom (useful if you ask for help). In none
of the cases below is anything deleted.

- **Key missing** — there is already Offload data on your device, but the key to open it is
  missing. Offload then deliberately does not create a new key: that would make your existing
  data unreadable for good. Nothing is changed.
- **Key unreadable** — the key is present, but cannot be read right now. Try again, or restart
  your device.
- **Data cannot be opened** — the encrypted database itself cannot be opened.
- **Offload cannot start** — something unexpected went wrong during startup.

There is no way yet to restore data in the app.
