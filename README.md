# DAG

Simple directed acyclic graphs for Ruby.

## History

This ruby gem started out as a fork of [kevinrutherford's dag implementation](https://github.com/kevinrutherford/dag). If you want to migrate
from his implementation to this one, have a look at the
[breaking changes](#breaking-changes). Have a look at
[performance improvements](#performance-improvements) to see why you might
want to migrate.

## Installation

Install the gem

```
gem install simple_dag
```

Or add it to your Gemfile and run `bundle`.

``` ruby
gem 'simple_dag'
```

## Usage

```ruby
require 'simple_dag'

dag = DAG.new

v1 = dag.add_vertex
v2 = dag.add_vertex
v3 = dag.add_vertex

dag.add_edge from: v1, to: v2
dag.add_edge from: v2, to: v3

v1.path_to?(v3)                  # => true
v3.path_to?(v1)                  # => false

dag.add_edge from: v3, to: v1        # => ArgumentError: A DAG must not have cycles

dag.add_edge from: v1, to: v2        # => ArgumentError: Edge already exists
dag.add_edge from: v1, to: v3
v1.successors                        # => [v2, v3]
```

See the specs for more detailed usage scenarios.

## Compatibility

Tested with Ruby 2.2, 2.3, 2.4, 2.5, JRuby, Rubinius.
Builds with Ruby 2.5 and JRuby are currently failing. See
[this issue](https://github.com/fsobanski/dag/issues/1) for details.

## Differences to [dag](https://github.com/kevinrutherford/dag)

### Breaking changes

- The function `DAG::Vertex#has_path_to?` aliased as
`DAG::Vertex#has_descendant?` and `DAG::Vertex#has_descendent?` has been renamed
to `DAG::Vertex#path_to?`. The aliases have been removed.

- The function `DAG::Vertex#has_ancestor?` aliased as
`DAG::Vertex#is_reachable_from?` has been renamed to
`DAG::Vertex#reachable_from?`. The aliases have been removed.

- The array of edges returned by `DAG#edges` is no longer sorted by insertion
order of the edges.

- `DAG::Vertex#path_to?` and `DAG::Vertex#reachable_from?` no longer raise
errors if the vertex passed as an argument is not a vertex in the same `DAG`.
Instead, they just return `false`.

- [Parallel edges](https://en.wikipedia.org/wiki/Multiple_edges) are no longer
allowed in the dag. Instead, `DAG#add_edge` raises an `ArgumentError` if you
try to add an edge between two adjacent vertices. If you want to model a
multigraph, you can add a weight payload to the edges that contains a natural
number.

### New functions

- `DAG#topological_sort` returns a topological sort of the vertices in the dag
in a theoretically optimal computational time complexity.

- `DAG#enumerated_edges` returns an `Enumerator` of the edges in the dag.

### Performance improvements

- The computational complexity of `DAG::Vertex#outgoing_edges` has
improved to a constant because the edges are no longer stored in one array in
the `DAG`. Instead, the edges are now stored in their respective source
`Vertex`.

- The performance of `DAG::Vertex#successors` has improved because firstly,
it depends on `DAG::Vertex#outgoing_edges` and secondly the call to
`Array#uniq` is no longer necessary since parallel edges are prohibited.

- The computational complexities of `DAG::Vertex#descendants`,
`DAG::Vertex#path_to?` and `DAG::Vertex#reachable_from?` have improved because
the functions depend on `DAG::Vertex#successors`

- I optimized `DAG::Vertex#path_to?` further in commit
fsobanski/simple_dag@5d8f8e52c9b9906ab89f00d420fe70d0344abf33

- I optimized `DAG::Vertex#descendants` further in commit
fsobanski/simple_dag@58f823312f9c4d88c2a52d8b875268069a3de173

- The computational complexity of `DAG::Vertex#incoming_edges` is
unchanged: Linear in the number of all edges in the `DAG`.

- The performance of `DAG::Vertex#predecessors` has improved because the call
to `Array#uniq` is no longer necessary since parallel edges are prohibited.

- The performance of `DAG::Vertex#ancestors` has improved because the function
depends on `DAG::Vertex#predecessors` and I optimized `DAG::Vertex#ancestors`
further in commit
fsobanski/simple_dag@/58f823312f9c4d88c2a52d8b875268069a3de173

- The computational complexity of `DAG::add_edge` has improved because the
cycle check in the function depends on `DAG::Vertex#path_to?`.

- The performance of `DAG#subgraph` has improved because the function depends
on `DAG::Vertex#descendants`, `DAG::Vertex#ancestors` and `DAG::add_edge`.
And I optimized `DAG#subgraph` further in commits
fsobanski/simple_dag@eda52e4b7698294e0ac576730eeec7c8f5ac1c20
and
fsobanski/simple_dag@6cd84ddfcd5174030bf8cd79c8b5dfeb5af2f0ea.

- The computational complexity of `DAG::edges` has worsened from a constant
complexity to a linear complexity. This is irrelevant if you want to iterate
over all the edges in the graph. You should consider using
`DAG#enumerated_edges` for a better space utilization.
