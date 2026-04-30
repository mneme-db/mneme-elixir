# TARGET SHAPE EXAMPLE:
# This script demonstrates intended persistence flow once native support is active.
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.save(collection, "docs.mneme")
{:ok, _loaded} = Mneme.Collection.load("docs.mneme")
