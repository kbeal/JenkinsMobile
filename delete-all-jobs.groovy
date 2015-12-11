for (item in Hudson.instance.items) {
println("Deleting: " + item.displayName)
item.delete()
}