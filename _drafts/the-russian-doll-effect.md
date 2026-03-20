---
layout: post
title: The russian doll effect
excerpt: 
permalink: 
category: 
cover_image: 
---

Currently working on how our controllers handle filtering, pagination, and serialization.

One idea explored was to push all this logic into a big abstraction that would handle everything, hide everything, and leave controllers very lean.

Problem: the complexity is not resolved, it's hidden. And hidden in a very confusing and coupling way.

The request comes in the controller. A filtering logic handle which attribute is returned or not. In this filtering gem, the pagination is handled as well. Then these nested logic would then be embeded in our serializing logic.

```
         +---+        +---+
         | ▲ |        | ▲ |
    +---------------------------+
    |       Serialization       |
 +--| +----------------------+  |--+
 |  | |      Pagination      |  |  |
 |  | | +-----------------+  |  |  |
 |  | | |    Filtering    |  |  |  |
    | | +-----------------+  |  |
    | +----------------------+  |
    +---------------------------+
```

