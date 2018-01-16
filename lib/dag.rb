require 'set'

require_relative 'dag/vertex'

class DAG
  Edge = Struct.new(:origin, :destination, :properties)

  attr_reader :vertices, :edges

  #
  # Create a new Directed Acyclic Graph
  #
  # @param [Hash] options configuration options
  # @option options [Module] mix this module into any created +Vertex+
  #
  def initialize(options = {})
    @vertices = []
    @edges = []
    @mixin = options[:mixin]
  end

  def add_vertex(payload = {})
    Vertex.new(self, payload).tap do |v|
      v.extend(@mixin) if @mixin
      @vertices << v
    end
  end

  def add_edge(attrs)
    origin = attrs[:origin] || attrs[:source] || attrs[:from] || attrs[:start]
    destination = attrs[:destination] || attrs[:sink] || attrs[:to] || attrs[:end]
    properties = attrs[:properties] || {}
    raise ArgumentError, 'Origin must be a vertex in this DAG' unless
      is_my_vertex?(origin)
    raise ArgumentError, 'Destination must be a vertex in this DAG' unless
      is_my_vertex?(destination)
    raise ArgumentError, 'A DAG must not have cycles' if origin == destination
    raise ArgumentError, 'A DAG must not have cycles' if destination.has_path_to?(origin)
    Edge.new(origin, destination, properties).tap { |e| @edges << e }
  end

  def subgraph(predecessors_of = [], successors_of = [])
    (predecessors_of + successors_of).each do |v|
      raise ArgumentError, 'You must supply a vertex in this DAG' unless
        is_my_vertex?(v)
    end

    result = self.class.new(mixin: @mixin)
    vertex_mapping = {}

    # Get the set of predecessors verticies and add a copy to the result
    predecessors_set = Set.new(predecessors_of)
    predecessors_of.each { |v| v.ancestors(predecessors_set) }

    predecessors_set.each do |v|
      vertex_mapping[v] = result.add_vertex(payload = v.payload)
    end

    # Get the set of successor vertices and add a copy to the result
    successors_set = Set.new(successors_of)
    successors_of.each { |v| v.descendants(successors_set) }

    successors_set.each do |v|
      vertex_mapping[v] = result.add_vertex(payload = v.payload) unless vertex_mapping.include? v
    end

    # get the unique edges
    edge_set = (
      predecessors_set.flat_map(&:incoming_edges) +
      successors_set.flat_map(&:outgoing_edges)
    ).uniq

    # Add them to the result via the vertex mapping
    edge_set.each do |e|
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
  # can be assumed in all practical cases, this method runs in O(n*m) where
  # m is the number of edges and n is the number of vertices because the method
  # successors of class Vertex uses the method outgoing_edges, which runs in
  # O(m). If the outgoing_edges of Vertex would be cached or precomputed then
  # this topological sorting could run in O(n+m).
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

  def is_my_vertex?(v)
    v.is_a?(Vertex) && (v.dag == self)
  end
end
