# Life Dashboard

- [ ] Set up the life dashboard app skeleton
- [ ] Publish notes and operations content as a private static site
  - [ ] Set up Quartz with my notes and other operations content {#quartz}
  - [ ] Serve the static site through Tailscale {depends: quartz}
- [ ] Set up Anki
- [ ] Move over fitness tracker
- [ ] Financial modeling with monte carlo
- [ ] Wanderlog replacement, integrated with google lists? can calculate optimal paths / integrate with insta
  - [ ] Google Places API (New): Text Search + Place Details by field mask, Place Photos; monthly free caps per SKU tier, keep requests in the cheapest tier that has the fields shown
  - [ ] Store only `place_id` + my notes; fetch details live on display (ToS forbids caching place content)
  - [ ] Show places on a Google map (Maps JS API, free monthly loads); Places data can't go on a non-Google map
  - [ ] Route by straight-line distance: haversine matrix + brute force / 2-opt per day; open Google Maps directions link for live travel times
  - [ ] Import Google Maps saved lists via Google Takeout ("Saved" → CSV per list); no API for lists
  - [ ] Import Instagram saved posts via "Download your information" JSON; no API for saves
  - [ ] Fallback without a key: Foursquare OS Places / Overture for search, Google Maps link per place for reviews
- [ ] Fundamentals Trading / Crypto trading apps
- [ ] open whisper
