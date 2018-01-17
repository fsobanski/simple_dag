require 'set'

class DAG
  class Vertex
    attr_reader :dag, :payload, :outgoing_edges

    def initialize(dag, payload)
      @dag = dag
      @payload = payload
      @outgoing_edges = []
    end

    private :initialize

    def incoming_edges
      @dag.enumerated_edges.select { |e| e.destination == self }
    end

    def predecessors
      incoming_edges.map(&:origin).uniq
    end

    def successors
      @outgoing_edges.map(&:destination).uniq
    end

    def inspect
      "DAG::Vertex:#{@payload.inspect}"
    end

    #
    # Is there a path from here to +other+ following edges in the DAG?
    #
    # @param [DAG::Vertex] another Vertex is the same DAG
    # @raise [ArgumentError] if +other+ is not a Vertex in the same DAG
    # @return true iff there is a path following edges within this DAG
    #
    def path_to?(other)
      raise ArgumentError, 'You must supply a vertex in this DAG' unless
        vertex_in_my_dag?(other)
      successors.include?(other) || successors.any? { |v| v.path_to? other }
    end

    #
    # Is there a path from +other+ to here following edges in the DAG?
    #
    # @param [DAG::Vertex] another Vertex is the same DAG
    # @raise [ArgumentError] if +other+ is not a Vertex in the same DAG
    # @return true iff there is a path following edges within this DAG
    #
    def reachable_from?(other)
      raise ArgumentError, 'You must supply a vertex in this DAG' unless
        vertex_in_my_dag?(other)
      other.path_to? self
    end

    #
    # Retrieve a value from the vertex's payload.
    # This is a shortcut for vertex.payload[key].
    #
    # @param key [Object] the payload key
    # @return the corresponding value from the payload Hash, or nil if not found
    #
    def [](key)
      @payload[key]
    end

    def ancestors(result_set = Set.new)
      predecessors.each do |v|
        unless result_set.include? v
          result_set.add(v)
          v.ancestors(result_set)
        end
      end
      result_set
    end

    def descendants(result_set = Set.new)
      successors.each do |v|
        unless result_set.include? v
          result_set.add(v)
          v.descendants(result_set)
        end
      end
      result_set
    end

    private

    def add_edge(destination, properties)
      Edge.new(self, destination, properties).tap { |e| @outgoing_edges << e }
    end

    def vertex_in_my_dag?(v)
      v.is_a?(Vertex) && (v.dag == dag)
    end
  end
end
