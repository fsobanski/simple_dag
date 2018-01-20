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
      incoming_edges.map(&:origin)
    end

    def successors
      @outgoing_edges.map(&:destination)
    end

    def inspect
      "DAG::Vertex:#{@payload.inspect}"
    end

    #
    # Is there a path from here to +other+ following edges in the DAG?
    #
    # @param [DAG::Vertex] another Vertex is the same DAG
    # @raise [ArgumentError] if +other+ is not a Vertex
    # @return true iff there is a path following edges within this DAG
    #
    def path_to?(other)
      raise ArgumentError, 'You must supply a vertex' unless other.is_a? Vertex
      visited = Set.new

      visit = lambda { |v|
        return false if visited.include? v
        return true if v.successors.lazy.include? other
        return true if v.successors.lazy.any? { |succ| visit.call succ }
        visited.add v
        false
      }

      visit.call self
    end

    #
    # Is there a path from +other+ to here following edges in the DAG?
    #
    # @param [DAG::Vertex] another Vertex is the same DAG
    # @raise [ArgumentError] if +other+ is not a Vertex
    # @return true iff there is a path following edges within this DAG
    #
    def reachable_from?(other)
      raise ArgumentError, 'You must supply a vertex' unless other.is_a? Vertex
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
        v.ancestors(result_set) unless result_set.add?(v).nil?
      end
      result_set
    end

    def descendants(result_set = Set.new)
      successors.each do |v|
        v.descendants(result_set) unless result_set.add?(v).nil?
      end
      result_set
    end

    private

    def add_edge(destination, properties)
      Edge.new(self, destination, properties).tap { |e| @outgoing_edges << e }
    end
  end
end
