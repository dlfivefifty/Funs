


## Vector of fun routines


function coefficients{N,D}(f::Vector{IFun{N,D}},o...)
    n=mapreduce(length,max,f)
    m=length(f)
    R=zeros(N,n,m)
    for k=1:m
        R[1:length(f[k]),k]=coefficients(f[k],o...)
    end
    R
end


function coefficients{T<:FFun}(B::Vector{T})
    m=mapreduce(length,max,B)
    fi=mapreduce(f->firstindex(f.coefficients),min,B)

    n=length(B)
    ret = zeros(Complex{Float64},m,length(B))
    for j=1:n
        for k=firstindex(B[j].coefficients):lastindex(B[j].coefficients)
            ret[k - fi + 1,j] = B[j].coefficients[k]
        end
    end
  
    ret
end


function values{N,D}(f::Vector{IFun{N,D}})
    n=mapreduce(length,max,f)
    m=length(f)
    R=zeros(N,n,m)
    for k=1:m
        R[:,k] = values(pad(f[k],n))
    end
    R
end

function values{T,D}(p::Array{IFun{T,D},2})
    @assert size(p)[1] == 1

   values(vec(p))
end







## evaluation


#TODO: fix for complex 
evaluate{T<:AbstractFun}(A::Vector{T},x::Real)=Float64[real(A[k][x]) for k=1:length(A)]
evaluate{T<:AbstractFun}(A::Array{T},x::Real)=Float64[real(A[k,j][x]) for k=1:size(A,1),j=1:size(A,2)]


function evaluate{T<:IFun}(A::Vector{T},x::Vector{Float64})
    x = tocanonical(first(A),x)

    n=length(x)
    ret=Array(Float64,length(A),n)
    
    bk=Array(Float64,n)
    bk1=Array(Float64,n)
    bk2=Array(Float64,n)
    
    for k=1:length(A)
        bkr=clenshaw(A[k].coefficients,x,bk,bk1,bk2)
        
        for j=1:n
            ret[k,j]=bkr[j]
        end
    end
    
    ret
end

function evaluate{T<:FFun}(A::Vector{T},x::Vector{Float64})
    x = tocanonical(first(A),x)

    n=length(x)
    ret=Array(Float64,length(A),n)
    
    for k=1:length(A)
        bk=horner(A[k].coefficients,x)
        
        for j=1:n
            ret[k,j]=bk[j]
        end
    end
    
    ret
end



## Algebra

## scalar fun times vector

*{T<:Union(Number,IFun)}(f::IFun,v::Vector{T})=typeof(f)[f.*v[k] for k=1:length(v)]
*{T<:Union(Number,IFun)}(v::Vector{T},f::IFun)=typeof(f)[v[k].*f for k=1:length(v)]
*(f::IFun,v::Vector{Any})=typeof(f)[f.*v[k] for k=1:length(v)]
*(v::Vector{Any},f::IFun)=typeof(f)[v[k].*f for k=1:length(v)]
 

#*{T<:IFun}(v::Vector{T},a::Vector)=IFun(coefficients(v)*a,first(v).domain) 


function *{T<:FFun}(v::Vector{T},a::Vector)
    fi=mapreduce(f->firstindex(f.coefficients),min,v)
    FFun(ShiftVector(coefficients(v)*a,1-fi),first(v).domain) 
end

# function *{N<:Number,D}(A::Array{N,2},p::Vector{IFun{N,D}})
#     cfs=A*coefficients(p).'
#     ret = Array(IFun{N,D},size(A)[1])
#     for i = 1:size(A)[1]
#         ret[i] = IFun(vec(cfs[i,:]),p[i].domain)
#     end
#     ret
# end

## Need to catch A*p, A'*p, A.'*p
##TODO: A may not be same type as p
for op in (:*,:(Base.Ac_mul_B),:(Base.At_mul_B))
    @eval begin
        function ($op){T<:Number,D}(A::Array{T,2}, p::Vector{IFun{T,D}})
            cfs=$op(A,coefficients(p).')
            ret = Array(IFun{T,D},size(cfs,1))
            for i = 1:size(A)[1]
                ret[i] = IFun(vec(cfs[i,:]),p[i].domain)
            end
            ret    
        end
    end
end