s3sync
======

Simple iOS library to managed synced resources from s3, uses AWS iOS SDK

Allows you to sync assets from specified buckets into a local storage directory of your choosing, store the etags, and only update assets with changed etags (i.e. assets that have been updated), or to reset the etags and update all assets.
