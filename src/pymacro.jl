"""
    @py expr

Evaluate `expr` but with Python semantics.

Currently, the following transformations are made (anything else is passed through unchanged):
* Conditionals (`if`, `elseif`, `while`, `||`, `&&`) use `pyistrue`.
* `x[i]` becomes `pygetitem(x, i)`.
* `x.a` becomes `pygetattr(x, :a)`.

To-do:
* Assignment (`=`) in in-place operations (`+=` etc).
* `import mod` => `mod = pyimport("mod")`
* `import mod: x, y` => `tmp=pyimport("mod"); x=tmp.x; y=tmp.y`
"""
macro py(ex)
    esc(MacroTools.postwalk(ex) do ex
        if ex isa Expr
            h = ex.head
            a = ex.args
            n = length(a)
            t = gensym()
            if h == :(||)
                @assert n==2
                return quote
                    $t = $(a[1])
                    pyistrue($t) ? $t : $(a[2])
                end
            elseif h == :(&&)
                @assert n==2
                return quote
                    $t = $(a[1])
                    pyistrue($t) ? $(a[2]) : $t
                end
            elseif h in (:if, :elseif)
                @assert n in (2,3)
                Expr(h, :(pyistrue($(a[1]))), a[2:end]...)
            elseif h == :while
                @assert n == 2
                Expr(h, :(pyistrue($(a[1]))), a[2])
            elseif h == :ref
                @assert n ≥ 1
                :(pygetitem($(a[1]), $(n==2 ? a[2] : Expr(:tuple, a[2:end]...))))
            elseif h == :.
                @assert n==2
                :(pygetattr($(a[1]), $(a[2])))
            elseif h == :call
                @assert n≥1
                f = a[1]
                if f == :(==) && n==3
                    return :(pyeq($(a[2]), $(a[3])))
                elseif f in (:(!=), :(≠)) && n==3
                    return :(pyne($(a[2]), $(a[3])))
                elseif f in (:(===), :(≡)) && n==3
                    return :(pyis($(a[2]), $(a[3])))
                elseif f in (:(!==), :(≢)) && n==3
                    return :(!pyis($(a[2]), $(a[3])))
                elseif f == :(<) && n==3
                    return :(pylt($(a[2]), $(a[3])))
                elseif f in (:(<=), :(≤)) && n==3
                    return :(pyle($(a[2]), $(a[3])))
                elseif f == :(>) && n==3
                    return :(pygt($(a[2]), $(a[3])))
                elseif f in (:(>=), :(≥)) && n==3
                    return :(pyge($(a[2]), $(a[3])))
                elseif f == :(!) && n==2
                    return :(pynot($(a[2])))
                else
                    return ex
                end
            else
                return ex
            end
        else
            return ex
        end
    end)
end
export @py
