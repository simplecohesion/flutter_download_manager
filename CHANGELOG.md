## [0.5.9] - Bug Fixes

* Fix queue worker cleanup to avoid leaked running task slots during early exits/cancellation.
* Prevent uncaught async errors from scheduler-launched downloads on failure.
* Ensure task progress reaches `1.0` on successful completion, including unknown content-length cases.
* Correct batch progress to count only `completed` downloads as successful completion.
* Add deterministic regression tests for scheduler and progress edge cases.
* Harden example app actions by waiting for storage init, guarding file deletes, and surfacing operation errors.

## [0.5.5] - Bug Fixes

* Update dio to 5.0.1 #10 mbfakourii 
* Replace slash with Platform.pathSeparator on downloader #12 (Paulo Ortolan)
* Fixed download task list #4 (arjundevlucid)
* Fixed initial progress error during resume, after multiple pause resumes (YanRui)

## [0.5.4] - Bug Fixes

* Improve batch progress notification to notify more granular

## [0.5.3] - Bug Fixes

* Disable Streams temporarily to fix bad state bugs
* Bug Fix: Stop Same Download Requests if already downloading
* Return DownloadTask  when addDownload

## [0.5.2] - Added Stream to expose events for all task when download status changes

* Added Stream to expose events for all task when download status changes

## [0.5.0] - Initial Release

* Introducing Flutter Download Manager.
