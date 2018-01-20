require 'set'

require_relative 'simple_dag/vertex'

class DAG
  Edge = Struct.new(:origin, :destination, :properties)

  attr_reader :vertices

  #
  # Create a new Directed Acyclic Graph
  #
  # @param [Hash] options configuration options
  # @option options [Module] mix this module into any created +Vertex+
  #
  def initialize(options = {})
    @vertices = []
    @mixin = options[:mixin]
    @n_of_edges = 0
  end

  def add_vertex(payload = {})
    Vertex.new(self, payload).tap do |v|
      v.extend(@mixin) if @mixin
      @vertices << v
    end
  end

  def add_edge(attrs)
    origin = attrs[:origin] || attrs[:source] || attrs[:from] || attrs[:start]
    destination = attrs[:destination] || attrs[:sink] || attrs[:to] ||
                  attrs[:end]
    properties = attrs[:properties] || {}
    raise ArgumentError, 'Origin must be a vertex in this DAG' unless
      my_vertex?(origin)
    raise ArgumentError, 'Destination must be a vertex in this DAG' unless
      my_vertex?(destination)
    raise ArgumentError, 'Edge already exists' if
      origin.successors.include? destination
    raise ArgumentError, 'A DAG must not have cycles' if origin == destination
    raise ArgumentError, 'A DAG must not have cycles' if
      destination.path_to?(origin)
    @n_of_edges += 1
    origin.send :add_edge, destination, properties
  end

  # @return Enumerator over all edges in the dag
  def enumerated_edges
    Enumerator.new(@n_of_edges) do |e|
      @vertices.each { |v| v.outgoing_edges.each { |out| e << out } }
    end
  end

  def edges
    enumerated_edges.to_a
  end

  def subgraph(predecessors_of = [], successors_of = [])
    (predecessors_of + successors_of).each do |v|
      raise ArgumentError, 'You must supply a vertex in this DAG' unless
        my_vertex?(v)
    end

    result = self.class.new(mixin: @mixin)
    vertex_mapping = {}

    # Get the set of predecessors verticies and add a copy to the result
    predecessors_set = Set.new(predecessors_of)
    predecessors_of.each { |v| v.ancestors(predecessors_set) }

    # Get the set of successor vertices and add a copy to the result
    successors_set = Set.new(successors_of)
    successors_of.each { |v| v.descendants(successors_set) }

    (predecessors_set + successors_set).each do |v|
      vertex_mapping[v] = result.add_vertex(v.payload)
    end

    predecessor_edges =
      predecessors_set.flat_map(&:outgoing_edges).select do |e|
        predecessors_set.include? e.destination
      end

    # Add the edges to the result via the vertex mapping
    (predecessor_edges | successors_set.flat_map(&:outgoing_edges)).each do |e|
      result.add_edge(
        from: vertex_mapping[e.origin],
        to: vertex_mapping[e.destination],
        properties: e.properties
      )
    end

    result
  end

  # Returns an array of the vertices in the graph in a topological order, i.e.
  # for every path in the dag from a vertex v to a vertex u, v comes before u
  # in the array.
  #
  # Uses a depth first search.
  #
  # Assuming that the method include? of class Set runs in linear time, which
  # can be assumed in all practical cases, this method runs in O(n+m) where
  # m is the number of edges and n is the number of vertices.
  def topological_sort
    result_size = 0
    result = Array.new(@vertices.length)
    visited = Set.new

    visit = lambda { |v|
      return if visited.include? v
      v.successors.each do |u|
        visit.call u
      end
      visited.add v
      result_size += 1
      result[-result_size] = v
    }

    @vertices.each do |v|
      next if visited.include? v
      visit.call v
    end

    result
  end

  private

  def my_vertex?(v)
    v.is_a?(Vertex) && (v.dag == self)
  end
end
