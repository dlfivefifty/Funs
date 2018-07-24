


canonicaldomain(d::ProductDomain) = ProductDomain(map(canonicaldomain,d.domains))

# product domains are their own canonical domain
for OP in (:fromcanonical,:tocanonical)
    @eval $OP(d::ProductDomain,x::Vec) = Vec(map($OP,d.domains,x)...)
end


nfactors(d::ProductDomain) = length(d.domains)
factor(d::ProductDomain,k::Integer) = d.domains[k]

function pushappendpts!(ret, xx, pts)
    if isempty(pts)
        push!(ret,Vec(xx...))
    else
        for x in pts[1]
            pushappendpts!(ret,(xx...,x),pts[2:end])
        end
    end
    ret
end

function checkpoints(d::ProductDomain)
    pts=map(checkpoints,d.domains)
    ret=Vector{Vec{length(d.domains),mapreduce(eltype,promote_type,d.domains)}}(undef, 0)

    pushappendpts!(ret,(),pts)
    ret
end

function points(d::ProductDomain,n::Tuple)
    @assert length(d.domains) == length(n)
    pts=map(points,d.domains,n)
    ret=Vector{Vec{length(d.domains),mapreduce(eltype,promote_type,d.domains)}}(undef, 0)
    pushappendpts!(ret,Vec(x),pts)
    ret
end

reverse(d::ProductDomain) = ProductDomain(map(reverse,d.domains))

domainscompatible(a::ProductDomain,b::ProductDomain) =
                        length(a.domains)==length(b.domains) &&
                        all(map(domainscompatible,a.domains,b.domains))
