export OSULatency

struct OSULatency <: MPIBenchmark
    conf::Configuration
    name::String
end

function OSULatency(T::Type=UInt8;
                     filename::Union{String,Nothing}="julia_osu_latency.csv",
                     kwargs...,
                     )
    return OSULatency(
        Configuration(T; filename, class=:osu_p2p, kwargs...),
        "OSU Latency",
    )
end

function osu_latency(T::Type, bufsize::Int, iters::Int, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    send_buffer = rand(T, bufsize)
    recv_buffer = rand(T, bufsize)
    tag = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i in 1:iters
        if iszero(rank)
            MPI.Send(send_buffer, comm; dest=1, tag)
            MPI.Recv!(recv_buffer, comm; source=1, tag)
        elseif isone(rank)
            MPI.Recv!(recv_buffer, comm; source=0, tag)
            MPI.Send(send_buffer, comm; dest=0, tag)
        end
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

Base.run(bench::OSULatency) = run_osu_p2p(bench, osu_latency, bench.conf)
