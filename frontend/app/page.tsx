'use client';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient } from 'wagmi';
import { useState, useEffect } from 'react';
import votingArtifact from '../abi/SimpleVotingSystem.json';

const CONTRACT_ADDRESS = '0xddb46ef53eEB95b755CC1F43558e78AeC308C117';
const ABI = votingArtifact.abi as any;

export default function Home() {
  const { address } = useAccount();
  const { writeContract, data: hash, error: writeError, isPending: isWritePending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });
  const publicClient = usePublicClient();

  // Local State
  const [candidateName, setCandidateName] = useState('');
  const [candidateAddr, setCandidateAddr] = useState('');
  const [candidates, setCandidates] = useState<any[]>([]);
  const [winner, setWinner] = useState<string>('');

  // Read Workflow Status
  const { data: statusData, refetch: refetchStatus } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: ABI,
    functionName: 'workflowStatus',
  });

  const statuses = [
    'REGISTER_CANDIDATES',
    'FOUND_CANDIDATES',
    'VOTE',
    'COMPLETED'
  ];

  const currentStatus = statusData !== undefined ? Number(statusData) : -1;

  // Fetch Candidates Loop
  useEffect(() => {
    if (!publicClient) return;
    const fetchCandidates = async () => {
      const list = [];
      // Try fetching up to 10 candidates (simple heuristic)
      for (let i = 0; i < 20; i++) {
        try {
          const data = await publicClient.readContract({
            address: CONTRACT_ADDRESS,
            abi: ABI,
            functionName: 'getCandidate',
            args: [BigInt(i)]
          }) as [string, bigint, string];

          list.push({
            index: i,
            name: data[0],
            voteCount: Number(data[1]),
            addr: data[2]
          });
        } catch (e) {
          // Likely index out of bounds, stop loop
          break;
        }
      }
      setCandidates(list);
    };

    fetchCandidates();
    refetchStatus();
  }, [publicClient, isConfirmed, refetchStatus]);

  // Actions
  const handleSetStatus = (newStatus: number) => {
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'setWorkflowStatus',
      args: [newStatus],
    });
  };

  const handleRegister = () => {
    if (!candidateName || !candidateAddr) return;
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'registerCandidate',
      args: [candidateName, candidateAddr],
    });
  };

  const handleVote = (index: number) => {
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'vote',
      args: [BigInt(index)],
    });
  }

  const handleFund = () => {
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'fundCandidates',
      value: BigInt(1000000000000000), // 0.001 ETH
    });
  }

  const handleWithdraw = () => {
    writeContract({
      address: CONTRACT_ADDRESS,
      abi: ABI,
      functionName: 'withdraw',
    });
  }

  const getWinner = async () => {
    if (!publicClient) return;
    try {
      const data = await publicClient.readContract({
        address: CONTRACT_ADDRESS,
        abi: ABI,
        functionName: 'getWinner',
      }) as [string, bigint];
      setWinner(`${data[0]} with ${data[1]} votes`);
    } catch (e) {
      console.error(e);
      alert("Cannot get winner yet");
    }
  }

  return (
    <div className="min-h-screen p-8 bg-gray-900 text-white font-[family-name:var(--font-geist-sans)]">
      <header className="flex justify-between items-center mb-10">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-600 bg-clip-text text-transparent">
          Voting DApp
        </h1>
        <ConnectButton />
      </header>

      <main className="max-w-4xl mx-auto space-y-8">
        {/* Status Section */}
        <section className="p-6 bg-gray-800 rounded-xl border border-gray-700 shadow-lg">
          <h2 className="text-xl font-semibold mb-4 text-blue-300">Phase du Workflow</h2>
          <div className="flex items-center space-x-4 mb-4">
            <div className={`px-4 py-2 rounded-full font-bold ${currentStatus >= 0 ? 'bg-green-900 text-green-300' : 'bg-gray-700'
              }`}>
              {currentStatus >= 0 ? statuses[currentStatus] : 'Loading...'}
            </div>
          </div>

          {/* Admin Controls */}
          <div className="flex flex-wrap gap-2 mt-4 pt-4 border-t border-gray-700">
            <p className="w-full text-sm text-gray-400 mb-2">Admin Controls (Set Status):</p>
            {statuses.map((s, idx) => (
              <button
                key={s}
                onClick={() => handleSetStatus(idx)}
                className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded text-xs transition-colors"
              >
                {idx}: {s}
              </button>
            ))}
          </div>
        </section>

        {/* Register Section (Only active in Phase 0) */}
        {currentStatus === 0 && (
          <section className="p-6 bg-gray-800 rounded-xl border border-gray-700 shadow-lg">
            <h2 className="text-xl font-semibold mb-4 text-purple-300">Enregistrer un Candidat</h2>
            <div className="flex gap-4">
              <input
                type="text"
                placeholder="Nom"
                className="p-2 rounded bg-gray-900 border border-gray-600 flex-1"
                value={candidateName}
                onChange={(e) => setCandidateName(e.target.value)}
              />
              <input
                type="text"
                placeholder="Adresse (0x...)"
                className="p-2 rounded bg-gray-900 border border-gray-600 flex-1"
                value={candidateAddr}
                onChange={(e) => setCandidateAddr(e.target.value)}
              />
              <button
                onClick={handleRegister}
                className="px-6 py-2 bg-purple-600 hover:bg-purple-500 rounded font-bold transition-colors"
              >
                Ajouter
              </button>
            </div>
          </section>
        )}

        {/* Candidates List */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {candidates.map((c) => (
            <div key={c.index} className="p-6 bg-gray-800 rounded-xl border border-gray-700 hover:border-blue-500 transition-all group">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-2xl font-bold">{c.name}</h3>
                <span className="bg-blue-900 text-blue-200 px-3 py-1 rounded text-sm">
                  {c.voteCount} Voix
                </span>
              </div>
              <p className="text-gray-500 text-xs mb-4">{c.addr}</p>

              <button
                onClick={() => handleVote(c.index)}
                disabled={currentStatus !== 2}
                className={`w-full py-2 rounded font-bold transition-colors ${currentStatus === 2
                  ? 'bg-green-600 hover:bg-green-500 text-white'
                  : 'bg-gray-700 text-gray-500 cursor-not-allowed'
                  }`}
              >
                {currentStatus === 2 ? 'Voter' : 'Vote Fermé'}
              </button>
            </div>
          ))}
          {candidates.length === 0 && (
            <div className="col-span-2 text-center text-gray-500 py-10">
              Aucun candidat trouvé.
            </div>
          )}
        </section>

        {/* Other Roles Actions */}
        <section className="p-6 bg-gray-800 rounded-xl border border-gray-700 shadow-lg flex gap-4 flex-wrap">
          <button
            onClick={handleFund}
            className="px-4 py-2 bg-yellow-700 hover:bg-yellow-600 rounded text-yellow-100"
          >
            Founder: Fund (0.001 ETH)
          </button>
          <button
            onClick={handleWithdraw}
            className="px-4 py-2 bg-red-700 hover:bg-red-600 rounded text-red-100"
          >
            Withdrawer: Withdraw All
          </button>
          <button
            onClick={getWinner}
            className="px-4 py-2 bg-teal-700 hover:bg-teal-600 rounded text-teal-100"
          >
            Get Winner
          </button>
          {winner && <span className="ml-4 text-green-400 font-bold self-center">Winner: {winner}</span>}
        </section>

        {/* Transaction Status */}
        {hash && (
          <div className="p-4 bg-gray-800 rounded border border-gray-600 text-sm break-all">
            <p className="text-gray-400">Transaction Hash:</p>
            <a
              href={`https://sepolia.etherscan.io/tx/${hash}`}
              target="_blank"
              className="text-blue-400 hover:underline"
            >
              {hash}
            </a>
            <p className="mt-2">
              {isConfirming ? 'Confirming...' : isConfirmed ? 'Confirmed!' : ''}
            </p>
            {writeError && <p className="text-red-500 mt-2">{(writeError as Error)?.message}</p>}
          </div>
        )}
      </main>
    </div>
  );
}
