require 'spec_helper'

describe DAG::Vertex do
  let(:dag) { DAG.new }
  subject { dag.add_vertex }
  let(:v1) { dag.add_vertex(name: :v1) }
  let(:v2) { dag.add_vertex(name: :v2) }
  let(:v3) { dag.add_vertex(name: 'v3') }

  describe '#path_to?' do
    it 'cannot have a path to a non-vertex' do
      expect { subject.path_to?(23) }.to raise_error(ArgumentError)
    end

    it 'cannot have a path to a vertex in a different DAG' do
      expect { subject.path_to?(DAG.new.add_vertex) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#reachable_from?' do
    it 'ancestors must be a vertex' do
      expect { subject.reachable_from?(23) }.to raise_error(ArgumentError)
    end

    it 'ancestors must be in the same DAG' do
      expect { subject.reachable_from?(DAG.new.add_vertex) }
        .to raise_error(ArgumentError)
    end
  end

  describe 'with a payload' do
    subject { dag.add_vertex(name: 'Fred', size: 34) }

    it 'allows the payload to be accessed' do
      expect(subject[:name]).to eq('Fred')
      expect(subject[:size]).to eq(34)
      expect(subject.payload).to eq(name: 'Fred', size: 34)
    end

    it 'returns nil for missing payload key' do
      expect(subject[56]).to be_nil
    end

    it 'allows the payload to be changed' do
      subject.payload[:another] = 'ha'
      expect(subject[:another]).to eq('ha')
    end
  end

  context 'with predecessors' do
    before do
      dag.add_edge from: v1, to: subject
      dag.add_edge from: v2, to: subject
    end

    it 'has the correct predecessors' do
      expect(subject.predecessors).to eq([v1, v2])
    end

    it 'has no successors' do
      expect(subject.successors).to be_empty
    end

    it 'has no paths to its predecessors' do
      expect(subject.path_to?(v1)).to be_falsey
      expect(subject.path_to?(v2)).to be_falsey
    end

    context 'with multiple paths' do
      it 'lists each predecessor only once' do
        dag.add_edge from: v1, to: subject
        expect(subject.predecessors).to eq([v1, v2])
      end
    end

    it 'has the correct ancestors' do
      expect(subject.reachable_from?(v1)).to be_truthy
      expect(subject.reachable_from?(v2)).to be_truthy
      expect(subject.reachable_from?(v3)).to be_falsey
    end
  end

  context 'with successors' do
    before do
      dag.add_edge from: subject, to: v1
      dag.add_edge from: subject, to: v2
    end

    it 'has no predecessors' do
      expect(subject.predecessors).to be_empty
    end

    it 'has the correct successors' do
      expect(subject.successors).to eq([v1, v2])
    end

    it 'has paths to its successors' do
      expect(subject.path_to?(v1)).to be_truthy
      expect(subject.path_to?(v2)).to be_truthy
    end

    context 'with multiple paths' do
      it 'lists each successor only once' do
        dag.add_edge from: subject, to: v1
        expect(subject.successors).to eq([v1, v2])
      end
    end

    it 'has no ancestors' do
      expect(subject.reachable_from?(v1)).to be_falsey
      expect(subject.reachable_from?(v2)).to be_falsey
    end
  end

  context 'in a deep DAG' do
    before do
      dag.add_edge from: subject, to: v1
      dag.add_edge from: v1, to: v2
    end

    it 'has a deep path to v2' do
      expect(subject.path_to?(v2)).to be_truthy
    end

    it 'has no path to v3' do
      expect(subject.path_to?(v3)).to be_falsey
    end

    it 'recognises that it is an ancestor of v2' do
      expect(v2.reachable_from?(subject)).to be_truthy
    end

    it 'is known to all descendants' do
      expect(v2.ancestors).to eq(Set.new([v1, subject]))
    end

    it 'knows has no ancestors' do
      expect(subject.ancestors).to eq(Set.new)
    end

    it 'knows has all descendants' do
      expect(subject.descendants).to eq(Set.new([v1, v2]))
    end
  end
end
