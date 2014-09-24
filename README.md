# Gather

[![Build Status](https://travis-ci.org/stdbrouw/gather.svg)](https://travis-ci.org/stdbrouw/gather)

Gather is a command-line tool that merges JSON files, with a twist: gather can optionally add metadata from the filename or the file's [stats](http://nodejs.org/api/fs.html#fs_class_fs_stats) to each dataset. Because sometimes filenames are just meaningless descriptors, but often they're not.

Install with [NPM](https://www.npmjs.org/) (bundled with [node.js](http://nodejs.org/)): 

```shell
npm install gather-cli -g
```

## Examples

Combine all of last month's analytics data into a single file, without losing track of when those analytics were recorded: 

```shell
gather 'analytics/{date}.json' > metrics.json
```

[Convert](https://github.com/stdbrouw/yaml2json) your Markdown blogposts with YAML frontmatter into JSON, bundle them together with Gather and then [render](https://github.com/stdbrouw/render) them: 

```shell
yaml2json posts \
    --output posts \
    --prose \
    --convert markdown
gather 'posts/{year}-{month}-{day}-{permalink}.json' \
    --annotate \
    --output posts/all.json
render post.jade
    --input posts/all.json \
    --output 'build/{year}/{permalink}.html' \
    --many
```

Reorganize your data with a gather-and-[groupby](https://github.com/stdbrouw/groupby) one-two punch:

```
gather 'staff/{department}/{username}.json' | \
groupby 'staff/{office}/{firstName}-{lastName}.json' --unique
```

## Path metadata

By default, filled-in filename placeholders will get added to the data.

With this gather command...

```shell
gather 'analytics/{date}.json' > metrics.json
```

... the resulting metrics.json file will contain a `date` key

```json
[
    {
        "date": "2014-10-01", 
        ...
    }, 
    {
        "date": "2014-10-02", 
        ...
    }, 
    ...
]
```

## File metadata

File metadata includes:

* an [extended JSON representation](https://github.com/stdbrouw/date-expand) of the file's created, modified and accessed date
* if the file path contains `{year}`, `{month}` and `{day}` placeholders, a date inferred from these variables in the same [extended JSON format](https://github.com/stdbrouw/date-expand)
* the file's absolute and relative path, basename and extension

While path metadata is enabled by default, file metadata is not. Use the `--annotate` flag to enable file metadata.

Here's an example of file metadata: 

```json
{
    "origin": {
        "relative": "...", 
        "absolute": "...", 
        "basename": "...", 
        "extension": "..."
    }, 
    "date": {
        "accessed": {
            "iso": "...", 
            "year": ..., 
            "month": ..., 
            "day": ...,
            ...
        }, 
        "modified": ..., 
        "created": ..., 
        "inferred": ...
    }
}
```

## Compact, underscored and extended metadata naming schemes

Metadata from the filename or from the file's [stats](http://nodejs.org/api/fs.html#fs_class_fs_stats) can conflict with keys already present in the data. If you are concerned about naming clashes, there are two ways to avoid this: 

* ask `gather` to either underscore any metadata with the `--scheme underscored` option
* put the original data under `data` and metadata under `metadata` with `--scheme extended`, as opposed to merging those in at the root.

An example of the extended naming scheme: 

```json
{
    "origin": "file path, extension et cetera", 
    "date": "created, modified, accessed and inferred dates", 
    "metadata": "metadata extracted from path placeholders", 
    "data": "the original data"
}
```

## Partial rebuilds

When adding additional metadata using the `--annotate` option, the origin of each piece of data that makes up the merged dataset will be a part of the output. This metadata makes it possible, on subsequent gathering operations, to only update or remove data that has changed rather than redoing the entire merge from scratch.

For example, you've added a new staff member at `/staff/smith.json` and would like to update the `staff.json` file which contains thousands of staff members. For every staff member in `/staff`, `gather` will first try to see if it can't get up-to-date information from the existing `staff.json` file. Only for `smith.json` it can't, so only the `smith.json` will need to be loaded and parsed from disk.

Especially when merging thousands of files, these partial rebuilds dramatically speed up gathering operations. Because the caching mechanism is generally safe (it will never use stale data, it will remove data for files that are no longer there, et cetera) it is enabled by default.

Nevertheless, it is possible to disable partial rebuilds: use `--force` to force a full redo of the merge. Alternatively, just `rm` the output file before using `gather`.

## Use from node.js

```javascript
var gather = require('gather-cli');
var source = 'examples/staff';
var options = {
    "extended": true, 
    "scheme": "underscored"
}
gather(source, options, function(err, staffMembers) {
    staffMembers.forEach(function(staff){
        console.log(staff.name);
    });
});
```
