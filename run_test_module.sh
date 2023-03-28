#!/usr/bin/bash
# Run this inside `nix develop`
set -e

DIR=$(pwd)

cd /tmp
rm -rf posts

hc-scaffold web-app posts --setup-nix true --template module --templates-path ${DIR}/.templates

cd posts

nix develop --command bash -c "
set -e
hc-scaffold entry-type post --zome posts_integrity --reference-entry-hash false --crud crud --link-from-original-to-each-update true --fields title:String:TextField,needs:Vec\<String\>:TextField
hc-scaffold entry-type comment --zome posts_integrity  --reference-entry-hash false --crud crud --link-from-original-to-each-update false --fields post_hash:ActionHash::Post
hc-scaffold entry-type like --zome posts_integrity  --reference-entry-hash false --crud crd --fields like_hash:Option\<ActionHash\>::Like,image_hash:EntryHash:Image,agent:AgentPubKey:SearchAgent
hc-scaffold entry-type certificate --zome posts_integrity  --reference-entry-hash true --crud cr --fields post_hash:ActionHash::Post,agent:AgentPubKey::certified,certifications_hashes:Vec\<EntryHash\>::Certificate,certificate_type:Enum::CertificateType:TypeOne.TypeTwo,dna_hash:DnaHash

hc-scaffold collection --zome posts_integrity  global all_posts post 
hc-scaffold collection --zome posts_integrity  by-author posts_by_author post
hc-scaffold collection --zome posts_integrity  global all_posts_entry_hash post:EntryHash
hc-scaffold collection --zome posts_integrity  by-author posts_by_author_entry_hash post:EntryHash

hc-scaffold link-type --zome posts_integrity  post like --delete true --bidireccional false
hc-scaffold link-type --zome posts_integrity  comment like:EntryHash --delete true --bidireccional true
hc-scaffold link-type --zome posts_integrity  certificate:EntryHash like --delete false --bidireccional false
hc-scaffold link-type --zome posts_integrity  agent:creator post:EntryHash --delete false --bidireccional true

hc-scaffold zome file_storage --coordinator dnas/forum/zomes/coordinator --integrity dnas/forum/zomes/integrity

cargo add -p file_storage hc_zome_file_storage_coordinator
echo \"extern crate hc_zome_file_storage_coordinator;\" > dnas/forum/zomes/coordinator/file_storage/src/lib.rs
cargo add -p file_storage_integrity hc_zome_file_storage_integrity
echo \"extern crate hc_zome_file_storage_integrity;\" > dnas/forum/zomes/integrity/file_storage/src/lib.rs

npm i

npm i -w ui @holochain-open-dev/file-storage
npm start
npm t

npm run format -w ui
npm run lint -w ui
npm run build -w ui
"
