# Time Tracker App

Time Trackker allows you to track your time in a easy way. Just press a button and you are already tracking. 
You Can have as many active trackers as you want as well keep a history of what you have monitored before.
And if you prefer a more focused desktop to monitor your tasks, you can also delete any trackings you want.

The app is built using Point-Free's The Composable Architecture.

In This App, I focused on how to handle time.
The main idea was to think of a tracking as having a beginning. And from this fact, it became very simple to evolve the app.
The app saves all trackings using the file system. And loads them at every startup. 
Even if you close the app, and restart your phone, if you had active timers running, they will be recovered.

Persistence was implemented in `TrackingPersistenceClient`. This provides a light interface for accessing the filesystem. While making it easy to swap implementations for live, testing or previews.

The main logic of the app is implemented in the reducers. Where we have rules for "ticking" a clock, for updating selections, sorting and all kinds of things. This logic is very independent. 

For its computations it relies only on its inputs, and when needed to communicate with the environment, this is achieved by firing Effects.

The App is well tested for the main functionality involving the Reducers. And because the whole UI is derived from the app State, we can be confident that the UI and main functionality will also work well.

The UI was implemented using SwiftUI. And because it is crossplatform, the project also works for iPhone, iPad and macOS.

These are the basics of the project.

In order to run it, it uses Xcode 14.2 and targets iOS 15. The only external dependency is TCA library.
To run the project, just open `TimeTracker.xcodeproj` and run.

I didn't add custom packages to this project, but it is very well structured in order to adopt something like SPM modules. 
