# VaporGraph

When working with Vapor and Fluent and the application has many models, especially with relationships, you can run into some issues:

* Two models loaded that refer to a parent will both query the database and get a different reference to (instance of) the parent record.
* Each function that modifies the model must either save it on the spot or hope that the code that called it is aware of all/any changes made and save it later.

This is a rather limited explanation, but if they resonate with you at all, you may see what I've tried to achieve with Graph.

As Vapor and Fluent are rapidly changing, I did not want to have too many assumptions baked into the Graph so it's designed to work in tandem with the existing framework rather than integrate too deeply with it.

## Brief Tutorial

### Make your models Graphable

The **Graphable** protocol allows your models to be stored in a Graph. It also implements the **Model** protocol from Vapor. In addition to the requirements of **Model**, **Graphable** would look something like this:

```Swift
class Person : Graphable {
    static var graphIdGenerator: GraphIdGenerator?

    public var graph: Graph?
    public var snapshot: Node?

    func deserialize(node: Node, in context: Context) throws {
        ... 
    }

    init(node: Node, in context: Context) throws {
        try deserialize(node: node, in: context)
    }
}
```

Note that each of the variables are optional so there is no need to initialise them in any way.

The graph and snapshot are used by some of the Graphable extension functions to store a reference to the graph the model belongs to, and take snapshots for tracking changes.

The graphIdGenerator is optional to use. Nothing can be stored in the graph without an id however so if you wish to add models to the graph before you save them for the first time, you will need to either manually set the id before insertion, or set the graphIdGenerator. The signature for the GraphIdGenerator type looks as follows:

```Swift
    public typealias GraphIdGenerator = (Graphable.Type) throws -> String
```

So it's just a function that takes a Graphable.Type and returns a String. This can obviously be specified as a function or a closure. The Graph library supplies some default implementations:

* **generateGraphUUID**: Uses the Swift Foundation UUID struct to create a UUID for the ID
* **generateGraphPostgreSQLID**: Will run a query calling for the nextval in the sequence created for a PostgreSQL database id

You can use these as simply as:

```Swift
class Person : Graphable {
    static var graphIdGenerator: GraphIdGenerator? = generateGraphUUID
}
```

The **deserialize** function plays the same role as the **Model** protocol's requirement for an **init**. The difference being that deserialize can be called on an existing reference to transform it's data to a known state. Since it has the same functionality as the required **init**, the init can be defined in your model to delegate to the **deserialize** function which can be seen above.

### Inserting models into a Graph

```Swift
var graph = Graph() // Create a new, empty graph
var person = Person(withName: "Tommy")

_ = try graph.inject(person) // Inject the person into the graph

try graph.sync() // Save anything with changes that is in the graph
```

### Snapshots 

The purpose of the snapshot is to store the last known saved state of a model. When injecting into the graph there is an optional parameter called **takeSnapshot**. Therefor if you queried a model directly from the database and wished to insert it, you would take a snapshot at that point.

```Swift
    var graph = Graph()
    var person = try Person.find(25)
    _ = try graph.inject(person, takeSnapshot = true) // Take a snapshot as we know that this is the state directly out of the database
    try graph.sync() // This should have no effect as the only thing in the graph has not been changed from it's snapshot
```

## Quick examples

```Swift
    var graph = Graph // Instantiate the graph

    var person : Person = try graph.find(1) // Finds a person by ID, either in the graph or in the database
    var people : [Person] = try graph.findMany("favoriteColor", "blue") // Finds all people with the favorite color "blue" in the database and injects them into the graph
```