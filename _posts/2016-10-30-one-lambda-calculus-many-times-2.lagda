---
title         : One λ-calculus, many times... (2)
date          : 2016-10-30 12:00:00
categories    : [compsci]
tags          : [draft, agda]
hide-implicit : true
extra-script : [agda-extra-script.html]
extra-style  : [agda-extra-style.html]
---

This post is a continuation of *[One λ-calculus, many times...]({% post_url 2016-03-20-one-lambda-calculus-many-times %})*, in which I explored the use of natural deduction and sequent calculus systems as type systems for the simply-typed lambda calculus.[^minproplog] In this post, I will have a look at the variants of these systems which have explicit structural rules: Gentzen's NJ and LJ.

<div class="hidden">
\begin{code}
import 2016-03-20-one-lambda-calculus-many-times as Part1
module 2016-10-30-one-lambda-calculus-many-times-2 where
\end{code}
</div>

The structure of this post will be similar to that of the previous installment---which means that we will start out by having a look at the syntax of NJ, then have a look at its semantics and relation to the system ND we discussed last time, and finally we will do the same for LJ. But first, the syntax:

\begin{code}
module Syntax (Atom : Set) where
\end{code}

We can reuse our notions of types and sequents from the previous post:

<div class="hidden">
\begin{code}
  open Part1.Syntax Atom hiding (w′)
  open import Algebra                 using (module Monoid)
  open import Data.Nat                using (ℕ; suc; zero)
  open import Data.Fin                using (Fin; suc; zero)
  open import Data.List               using (List; _∷_; []; _++_)
  open import Data.List.Any           using (module Membership; here; there)
  open import Data.Product            using (proj₁; proj₂)
  open import Function                using (_$_)
  open import Function.Equivalence    using (_⇔_; id; map; equivalence)
  open import Relation.Binary.PropositionalEquality
  open Membership (setoid Type)       using (_∈_; _⊆_)
  open Monoid (Data.List.monoid Type) using () renaming (identity to ++-identity; assoc to ++-assoc)
  ++-identityʳ = proj₂ ++-identity
\end{code}
</div>
<pre class="Agda Spec">  <a name="2644" class="Keyword">data</a><a name="2648"> </a><a name="2649" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="2653"> </a><a name="2654" class="Symbol">:</a><a name="2655"> </a><a name="2656" class="PrimitiveType">Set</a><a name="2659"> </a><a name="2660" class="Keyword">where</a><a name="2665">
    </a><a name="2670" href="/2016/one-lambda-calculus-many-times/#2670" class="InductiveConstructor">El</a><a name="2672">  </a><a name="2674" class="Symbol">:</a><a name="2675"> </a><a name="2676" href="/2016/one-lambda-calculus-many-times/#1574" class="Bound">Atom</a><a name="2680"> </a><a name="2681" class="Symbol">→</a><a name="2682"> </a><a name="2683" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="2687">
    </a><a name="2692" href="/2016/one-lambda-calculus-many-times/#2692" class="InductiveConstructor Operator">_⇒_</a><a name="2695"> </a><a name="2696" class="Symbol">:</a><a name="2697"> </a><a name="2698" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="2702"> </a><a name="2703" class="Symbol">→</a><a name="2704"> </a><a name="2705" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="2709"> </a><a name="2710" class="Symbol">→</a><a name="2711"> </a><a name="2712" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a>

  <a name="3950" class="Keyword">data</a><a name="3954"> </a><a name="3955" href="/2016/one-lambda-calculus-many-times/#3955" class="Datatype">Sequent</a><a name="3962"> </a><a name="3963" class="Symbol">:</a><a name="3964"> </a><a name="3965" class="PrimitiveType">Set</a><a name="3968"> </a><a name="3969" class="Keyword">where</a><a name="3974">
    </a><a name="3979" href="/2016/one-lambda-calculus-many-times/#3979" class="InductiveConstructor Operator">_⊢_</a><a name="3982"> </a><a name="3983" class="Symbol">:</a><a name="3984"> </a><a name="3985" href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#52" class="Datatype" target="_blank">List</a><a name="3989"> </a><a name="3990" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="3994"> </a><a name="3995" class="Symbol">→</a><a name="3996"> </a><a name="3997" href="/2016/one-lambda-calculus-many-times/#2649" class="Datatype">Type</a><a name="4001"> </a><a name="4002" class="Symbol">→</a><a name="4003"> </a><a name="4004" href="/2016/one-lambda-calculus-many-times/#3955" class="Datatype">Sequent</a></pre>

Now, the usual axiomatisation for NJ is as follows:

$$
  \begin{array}{c}
  \frac{}{A \vdash A}{\small ax}
  \quad
  \frac{A , \Gamma \vdash B}{\Gamma \vdash A \Rightarrow B}{\small{\Rightarrow}\!i}
  \quad
  \frac{\Gamma \vdash A \Rightarrow B \quad \Delta \vdash A}{\Gamma , \Delta \vdash B}{\small{\Rightarrow}\!e}
  \\
  \\
  \frac{\Gamma \vdash B}{A , \Gamma \vdash B}{\small w}
  \quad
  \frac{A , A , \Gamma \vdash B}{A , \Gamma \vdash B}{\small c}
  \quad
  \frac{\Gamma , A , B , \Delta \vdash C}{\Gamma , B , A , \Delta \vdash C}{\small p}
  \end{array}
$$

<br />
There are three notable changes when comparing this to the system SC:

  - **Weakening**. The axiom no longer allows for arbitrary contexts to be present, it *has* to be $$A \vdash A$$. An implication of this is that we no longer have the option to have *unused* formulas in our context. If we *do* want to have unused formulas, we can add these using the *weakening* rule (or $$w$$).

  - **Contraction**. When we apply a binary rule, we no longer pass the entire context to both sides---instead, we have to choose how to *split* the context. So what do we do if there is a formula which we want to use in *both* branches of the proof? We can use the *contraction* (or $$c$$) rule, which *copies* a formula, and then pass a copy to either branch.

  - **Permutation**. The third change lies in the structure of our contexts and with the $$ax$$ rule. In the previous system, we thought of our contexts as *sets*, even though we implemented them with lists. This showed itself in the definition of the $$ax$$ rule, which took an extra argument---a proof that the desired type $$A$$ was a member of the context $$\Gamma$$:

    $$
      \frac{A \in \Gamma}{\Gamma \vdash A}{\small ax}
    $$

    When we start thinking of the contexts as *lists*, we lose the ability to have variables point to arbitrary positions in the context---they can only point to the *first* element in the context. In other words, our system is *ordered*. To regain the freedom we've lost, we add a third new rule which allows us to swap elements in the context: permutation (or $$p$$).

Below, I've implemented the resulting system in Agda:

\begin{code}
  infix 3 NJ_

  data NJ_ : Sequent → Set where
    ax : ∀ {A        } → NJ A ∷ [] ⊢ A
    ⇒i : ∀ {A B   Γ  } → NJ A ∷ Γ ⊢ B → NJ Γ ⊢ A ⇒ B
    ⇒e : ∀ {A B   Γ Δ} → NJ Γ ⊢ A ⇒ B → NJ Δ ⊢ A → NJ Γ ++ Δ ⊢ B
    w  : ∀ {A B   Γ  } → NJ Γ ⊢ B → NJ A ∷ Γ ⊢ B
    c  : ∀ {A B   Γ  } → NJ A ∷ A ∷ Γ ⊢ B → NJ A ∷ Γ ⊢ B
    p  : ∀ {A B C} → ∀ Γ → ∀ {Δ} → NJ Γ ++ A ∷ B ∷ Δ ⊢ C → NJ Γ ++ B ∷ A ∷ Δ ⊢ C
\end{code}



### Admissible Structural Rules in ND

If we are to have any hope of proving the equivalence between the implicit and the explicit systems, we should be able to prove that the implicit systems admit[^admit] the same structural rules. In the previous post, we've already proven the following theorem for ND:

> If $$\Gamma \subseteq \Gamma\prime$$ and $$\Gamma \vdash A$$, then
> $$\Gamma\prime \vdash A$$.

<div class="hidden">
\begin{code}
  module ND where
    open Part1.Syntax Atom public using (w′)
\end{code}
</div>

And we've also shown that we can very easily use this theorem to define weakening, because <a class="Agda InductiveConstructor Spec" target="_blank" href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1227">there</a> is a proof that "weakening", i.e. <span class="Agda Spec"><a class="Bound">Γ</a> <a href="https://agda.github.io/agda-stdlib/Data.List.Any.html#3056" class="Function Operator" target="_blank">⊆</a> <a class="Bound">A</a> <a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a> <a class="Bound">Γ</a></span>, holds for the subset relationship.

<pre class="Agda Spec">    <a href="/2016/one-lambda-calculus-many-times/#8603" class="Function">w′</a><a> </a><a class="Symbol">:</a><a> </a><a href="/2016/one-lambda-calculus-many-times/#5371" class="Datatype Operator">ND</a><a> </a><a class="Bound">Γ</a><a> </a><a href="/2016/one-lambda-calculus-many-times/#3979" class="InductiveConstructor Operator">⊢</a><a> </a><a class="Bound">B</a><a> </a><a class="Symbol">→</a><a> </a><a href="/2016/one-lambda-calculus-many-times/#5371" class="Datatype Operator">ND</a><a> </a><a class="Bound">A</a><a> </a><a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a><a> </a><a class="Bound">Γ</a><a> </a><a href="/2016/one-lambda-calculus-many-times/#3979" class="InductiveConstructor Operator">⊢</a><a> </a><a class="Bound">B</a><a>
    </a><a href="/2016/one-lambda-calculus-many-times/#8603" class="Function">w′</a><a> </a><a class="Symbol">=</a><a> </a><a href="/2016/one-lambda-calculus-many-times/#7305" class="Function">struct</a><a> </a><a href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1227" class="InductiveConstructor" target="_blank">there</a></pre>

Therefore, all we need to show to extend this to contraction and permutation is that their respective equations, <span class="Agda Spec"><a class="Bound">A</a> <a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a> <a class="Bound">A</a> <a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a> <a class="Bound">Γ</a> <a href="https://agda.github.io/agda-stdlib/Data.List.Any.html#3056" class="Function Operator" target="_blank">⊆</a> <a class="Bound">A</a> <a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a> <a class="Bound">Γ</a></span> and <span class="Agda Spec"><a class="Bound">Γ</a><a> </a><a href="https://agda.github.io/agda-stdlib/Data.List.Base.html#895" class="Function Operator" target="_blank">++</a><a> </a><a class="Bound">A</a><a> </a><a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a><a> </a><a class="Bound">B</a><a> </a><a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a><a> </a><a class="Bound">Δ</a><a> </a><a href="https://agda.github.io/agda-stdlib/Data.List.Any.html#3056" class="Function Operator" target="_blank">⊆</a><a> </a><a class="Bound">Γ</a><a> </a><a href="https://agda.github.io/agda-stdlib/Data.List.Base.html#895" class="Function Operator" target="_blank">++</a><a> </a><a class="Bound">B</a><a> </a><a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a><a> </a><a class="Bound">A</a><a> </a><a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#104" class="InductiveConstructor Operator" target="_blank">∷</a><a> </a><a class="Bound">Δ</a></span>, hold for the subset relation as well. This is simply a matter of reindexing. For contraction, if our "index" (made up of <a class="Agda Spec InductiveConstructor" target="_blank" href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1174">here</a> and <a class="Agda InductiveConstructor Spec" target="_blank" href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1227">there</a>) points to the first formula, we keep it the same. Otherwise, we subtract one. That way, the first two formulas are *contracted*, and the rest is adjusted accordingly.

\begin{code}
    c′ : ∀ {A B Γ} → ND A ∷ A ∷ Γ ⊢ B → ND A ∷ Γ ⊢ B
    c′ {A} = struct contract′
      where
        contract′ : ∀ {A Γ} → A ∷ A ∷ Γ ⊆ A ∷ Γ
        contract′ (here px) = here px
        contract′ (there i) = i
\end{code}

And for permutation, we skip through our index until we've passed the $$\Gamma$$ portion of the context, and then we swap the first two formulas.

\begin{code}
    p′ : ∀ {A B C} → ∀ Γ → ∀ {Δ} → ND Γ ++ A ∷ B ∷ Δ ⊢ C → ND Γ ++ B ∷ A ∷ Δ ⊢ C
    p′ Γ = struct (permute′ Γ)
      where
        permute′ : ∀ {A B} → ∀ Γ → ∀ {Δ} → Γ ++ A ∷ B ∷ Δ ⊆ Γ ++ B ∷ A ∷ Δ
        permute′ []      (here px)         = there (here px)
        permute′ []      (there (here px)) = here px
        permute′ []      (there (there i)) = there (there i)
        permute′ (C ∷ Γ) (here px)         = here px
        permute′ (C ∷ Γ) (there i)         = there (permute′ Γ i)
\end{code}

So, do we have enough to prove equivalence between the two systems? No, sadly we do not. If we have a look at the two versions of $$\small{\Rightarrow}\!e$$, we see that they use contexts quite differently...

$$
  \frac{\Gamma \vdash A \Rightarrow B \quad \Gamma \vdash A}{\Gamma \vdash B}{\small{\Rightarrow}\!e}
  \quad
  \frac{\Gamma \vdash A \Rightarrow B \quad \Delta \vdash A}{\Gamma , \Delta \vdash B}{\small{\Rightarrow}\!e}
$$

If we were to try and use the second version to simulate the first, we'd find that we end up with *two* copies of the context $$\Gamma$$. We would need some souped up version of contraction to contract these two contexts back into one... If, on the other hand, we were to try and use the first version to simulate the second, we run into a different problem: the first version of $$\small{\Rightarrow}\!e$$ expects both premises to *share* a context, but the premises have contexts $$\Gamma$$ and $$\Delta$$, respectively. So we need two versions of weakening which can add an entire *context* to the right or left, respectively.

$$
  \frac{\Gamma , \Gamma \vdash B}{\Gamma \vdash B}{\small c^+}
  \quad
  \frac{\Gamma \vdash B}{\Gamma , \Delta \vdash B}{\small w^l}
  \quad
  \frac{\Delta \vdash B}{\Gamma , \Delta \vdash B}{\small w^r}
$$

At this point, it may be a better idea to just derive a new, more permissive set of structural rules. This is what we'll do in the next section.

### More Expressive Structural Rules

The usual structural rules for NJ are theoretically sufficient, but in practice they are rather limiting. Therefore, in this section, we will present more permissive variants, and show that they too are admissible in ND. Below you will see the more expressive variants of the structural rules. Instead of weakening, contracting or permuting formulas, these rules permute entire contexts.

I've added one new rule, $$\small f^+$$ or "forward". It's in parenthesis because it is an obvious instance of permutation. I've nontheless added it, because it is a useful lemma on the way to proving permutation.

$$
  \frac{\Delta \vdash B}{\Gamma , \Delta \vdash B}{\small w^+}
  \quad
  \left(
  \frac{\Gamma , \Sigma , A , \Delta \vdash C}{\Gamma , A , \Sigma , \Delta \vdash C}{\small f^+}
  \right)
  \quad
  \frac{\Gamma , \Sigma , \Pi , \Delta \vdash C}{\Gamma , \Pi , \Sigma , \Delta \vdash C}{\small p^+}
  \quad
  \frac{\Gamma , \Gamma , \Delta \vdash B}{\Gamma , \Delta \vdash B}{\small c^+}
$$


Since we already have a structural theorem (<a href="/2016/one-lambda-calculus-many-times/#7305" class="Agda Spec Function">struct</a>) for ND, we only have to show that these equations hold for the subset relationship.

$$
  \begin{array}{crcl}
  (w^{+}) & {\Delta} & \subseteq & {\Gamma , \Delta} \\
  (f^{+}) & {\Gamma , \Sigma , A , \Delta} & \subseteq & {\Gamma , A , \Sigma , \Delta} \\
  (p^{+}) & {\Gamma , \Sigma , \Pi , \Delta} & \subseteq & {\Gamma , \Pi , \Sigma , \Delta} \\
  (c^{+}) & {\Gamma , \Gamma , \Delta} & \subseteq & {\Gamma , \Delta}
  \end{array}
$$


Weakening is still quite trivial. Instead of applying <a class="Agda InductiveConstructor Spec" target="_blank" href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1227">there</a> once, we now apply it multiple times, until we've removed the entire context $$\Gamma$$.

\begin{code}
    weaken : ∀ Γ → ∀ {Δ} → Δ ⊆ Γ ++ Δ
    weaken []      i = i
    weaken (A ∷ Γ) i = there (weaken Γ i)
\end{code}

Forwards movement, or $$\small f^+$$, is a little bit more involved: we move a formula $$A$$ past a context $$\Sigma$$. We do so without moving any formulas in the prefix $$\Gamma$$ or the suffix $$\Delta$$. The definition of forwards movement is split into two maps on indices: <a class="Agda Spec Function">forward</a> and <a class="Agda Spec Function">forward′</a>. In <a class="Agda Spec Function">forward</a>, we define the mapping for indices which point to some position in $$\Gamma$$; nothing changes. Once we have moved past $$\Gamma$$, we enter the nested function <a class="Agda Spec Function">forward′</a>, and $$\Sigma$$. Here, we start moving each index one position back, to make room for the formula $$A$$. Once we move past $$\Sigma$$, and find the index pointint to $$A$$, all we have to do is return <a class="Agda Spec InductiveConstructor" target="_blank" href="https://agda.github.io/agda-stdlib/Data.List.Any.html#1174">here</a>. Nothing has to change for the indices pointing into $$\Delta$$.

\begin{code}
    forward : ∀ {A} → ∀ Γ Σ → ∀ {Δ} → (Γ ++ Σ) ++ A ∷ Δ ⊆ (Γ ++ A ∷ Σ) ++ Δ
    forward (C ∷ Γ) Σ (here px) = here px
    forward (C ∷ Γ) Σ (there i) = there (forward Γ Σ i)
    forward []      Σ        i  = forward′ Σ i
      where
        forward′ : ∀ {A} → ∀ Σ → ∀ {Δ} → Σ ++ A ∷ Δ ⊆ A ∷ Σ ++ Δ
        forward′      []        i  = i
        forward′ (C ∷ Σ) (here px) = there (here px)
        forward′ (C ∷ Σ) (there i) with forward′ Σ i
        forward′ (C ∷ Σ) (there i) | here px = here px
        forward′ (C ∷ Σ) (there i) | there j = there (there j)
\end{code}

With a rule for forwards movement in hand, we can start to prove permutation. The proof itself is broken down in *two* cases: $$\Pi = \emptyset$$ and $$\Pi = A , \Pi'$$.

$$
    \frac
    {\Gamma , \Sigma , \emptyset , \Delta \vdash C}
    {\Gamma , \emptyset , \Sigma , \Delta \vdash C}
    \quad
    \frac
    {\Gamma , \Sigma , A , \Pi' , \Delta \vdash C}
    {\Gamma , A , \Pi' , \Sigma , \Delta \vdash C}
$$

The first case is trivial, and simply requires rewriting by proofs of right identity and associativity (as the actual sequent is $$((\Gamma,\Sigma), (\emptyset,\Delta))$$). For the second case, we prove the statement by moving the $$A$$ forwards across the $$\Sigma$$ (using $$\small f^+$$) and then permuting $$\Sigma$$ and $$\Pi'$$. The proof in Agda, however, is rather hard to read. This is because there is no pleasant way to intersperse code and rewrites (à la <a class="Agda Spec Keyword">rewrite</a>). To help you decipher the proof, I've inserted the intermediate terms as comments.

\begin{code}
    permute : ∀ Γ Σ Π → ∀ {Δ} → (Γ ++ Σ) ++ (Π ++ Δ) ⊆ (Γ ++ Π) ++ (Σ ++ Δ)
    permute Γ Σ [] {Δ} i
           -- x ∈ (Γ ++ Π) ++ [] ++ Δ
      rewrite ++-identityʳ Γ
           -- x ∈ (Γ ++ Π) ++ Δ
            | ++-assoc Γ Σ Δ
           -- x ∈ Γ ++ Π ++ Δ
            = i

    permute Γ Π (A ∷ Σ) {Δ} i
           -- x ∈ (Γ ++ A ∷ Σ) ++ Π ++ Δ
      rewrite sym (++-assoc Γ (A ∷ []) Σ)
           -- x ∈ ((Γ ++ A ∷ []) ++ Σ) ++ Π ++ Δ
            = permute (Γ ++ A ∷ []) Π Σ j
        where
          j : _ ∈ ((Γ ++ A ∷ []) ++ Π) ++ Σ ++ Δ
          j rewrite ++-assoc Γ (A ∷ []) Π
                 -- x ∈ (Γ ++ A ∷ Π) ++ Σ ++ Δ
                  = forward Γ Π i
\end{code}

In our previous version of contraction, all we had to do was merge any references to the first two formulas in our context.

\begin{code}
    contract : ∀ Γ → ∀ {Δ} → (Γ ++ Γ) ++ Δ ⊆ Γ ++ Δ
    contract []      {Δ} i = i
    contract (A ∷ Γ) {Δ} (here px) = here px
    contract (A ∷ Γ) {Δ} (there i)
      rewrite ++-assoc Γ (A ∷ Γ) Δ with forward [] Γ i
    contract (A ∷ Γ) {Δ} (there i) | here px = here px
    contract (A ∷ Γ) {Δ} (there i) | there j
      rewrite sym (++-assoc Γ Γ Δ) = there (contract Γ j)
\end{code}

Boop.

\begin{code}
    w⁺′ : ∀ {A} → ∀ Γ → ∀ {Δ} → ND Δ ⊢ A → ND Γ ++ Δ ⊢ A
    w⁺′ Γ = struct (weaken Γ)

    c⁺′ : ∀ {A} → ∀ Γ → ∀ {Δ} → ND (Γ ++ Γ) ++ Δ ⊢ A → ND Γ ++ Δ ⊢ A
    c⁺′ Γ = struct (contract Γ)

    p⁺′ : ∀ {A} → ∀ Γ Σ Π → ∀ {Δ} → ND (Γ ++ Σ) ++ (Π ++ Δ) ⊢ A
                 → ND (Γ ++ Π) ++ (Σ ++ Δ) ⊢ A
    p⁺′ Γ Σ Π = struct (permute Γ Σ Π)
\end{code}

Boop.

<div class="foldable">
\begin{code}
    s⁺′ : ∀ {A} → ∀ Γ Σ → ∀ {Π} → ND (Γ ++ Σ) ++ Π ⊢ A
                → ND (Γ ++ Π) ++ Σ ⊢ A
    s⁺′ {A} Γ Σ {Π} f
      = subst (λ Σ → ND (Γ ++ Π) ++ Σ ⊢ A)      (++-identityʳ Σ)
      $ p⁺′ Γ Σ Π
      $ subst (λ Π → ND (Γ ++ Σ) ++ Π ⊢ A) (sym (++-identityʳ Π))
      $ f
\end{code}
</div>



### Deriving Structural Rules in NJ

<div class="hidden">
\begin{code}
  module NJ where
\end{code}
</div>

We can derive these same extended structural rules in NJ. For instance, below we derive the equivalent weakening rule:

\begin{code}
    w⁺′ : ∀ {A} → ∀ Γ → ∀ {Δ} → NJ Δ ⊢ A → NJ Γ ++ Δ ⊢ A
    w⁺′ []      f = f
    w⁺′ (B ∷ Γ) f = w (w⁺′ Γ f)
\end{code}

The remainder of the proofs are rather similar to those for ND,

<div class="foldable">
\begin{code}
    f⁺′ : ∀ {A B} → ∀ Γ Σ → ∀ {Δ} → NJ (Γ ++ Σ) ++ (A ∷ Δ) ⊢ B
                → NJ (Γ ++ A ∷ Σ) ++ Δ ⊢ B
    f⁺′ {A} {B} Γ [] {Δ} f
           -- NJ (Γ ++ A ∷ []) ++ Δ ⊢ .B
      rewrite ++-identityʳ Γ
           -- NJ (Γ ++ A ∷ []) ++ Δ ⊢ B
            | ++-assoc Γ (A ∷ []) Δ
           -- NJ Γ ++ A ∷ Δ ⊢ B
            = f

    f⁺′ {A} {B} Γ (C ∷ Σ) {Δ} f
      rewrite ++-assoc Γ (A ∷ C ∷ Σ) Δ
           -- NJ Γ ++ A ∷ C ∷ Σ ++ Δ ⊢ B
            = p Γ g
        where
          g : NJ Γ ++ C ∷ A ∷ Σ ++ Δ ⊢ B
          g rewrite sym (++-assoc Γ (C ∷ []) (A ∷ Σ ++ Δ))
                 -- NJ (Γ ++ C ∷ []) ++ A ∷ Σ ++ Δ ⊢ B
                  | sym (++-assoc (Γ ++ C ∷ []) (A ∷ Σ) Δ)
                 -- NJ ((Γ ++ C ∷ []) ++ A ∷ Σ) ++ Δ ⊢ B
                 = f⁺′ (Γ ++ C ∷ []) Σ {Δ} h
              where
                h : NJ ((Γ ++ C ∷ []) ++ Σ) ++ A ∷ Δ ⊢ B
                h rewrite ++-assoc Γ (C ∷ []) Σ = f
\end{code}
</div>
<div class="foldable">
\begin{code}
    p⁺′ : ∀ {A} → ∀ Γ Σ Π → ∀ {Δ} → NJ (Γ ++ Σ) ++ (Π ++ Δ) ⊢ A
                  → NJ (Γ ++ Π) ++ (Σ ++ Δ) ⊢ A
    p⁺′ {A} Γ Σ [] {Δ} f
           -- NJ (Γ ++ []) ++ Σ ++ Δ ⊢ A
      rewrite ++-identityʳ Γ
           -- NJ Γ ++ Σ ++ Δ ⊢ A
            | sym (++-assoc Γ Σ Δ)
           -- NJ (Γ ++ Σ) ++ Δ ⊢ A
            = f

    p⁺′ {A} Γ Σ (B ∷ Π) {Δ} f
           -- NJ (Γ ++ B ∷ Π) ++ Σ ++ Δ ⊢ A
      rewrite sym (++-assoc Γ (B ∷ []) Π)
           -- NJ ((Γ ++ B ∷ []) ++ Π) ++ Σ ++ Δ ⊢ A
            = p⁺′ (Γ ++ B ∷ []) Σ Π {Δ} g
        where
          g : NJ ((Γ ++ B ∷ []) ++ Σ) ++ Π ++ Δ ⊢ A
          g rewrite ++-assoc Γ (B ∷ []) Σ
                 -- NJ (Γ ++ B ∷ Σ) ++ Π ++ Δ ⊢ A
                  = f⁺′ Γ Σ f
\end{code}
</div>
<div class="foldable">
\begin{code}
    c⁺′ : ∀ {A} → ∀ Γ → ∀ {Δ} → NJ (Γ ++ Γ) ++ Δ ⊢ A → NJ Γ ++ Δ ⊢ A
    c⁺′ {A} []      {Δ} f = f
    c⁺′ {A} (B ∷ Γ) {Δ} f = c $ p⁺′ [] Γ (B ∷ B ∷ [])        $ c⁺′ Γ
                      $ p⁺′ [] (B ∷ B ∷ []) (Γ ++ Γ) $ g
      where
        g : NJ (B ∷ B ∷ Γ ++ Γ) ++ Δ ⊢ A
        g rewrite ++-assoc (B ∷ B ∷ Γ) Γ Δ
                = f⁺′ [] (B ∷ Γ) h
            where
              h : NJ B ∷ Γ ++ B ∷ Γ ++ Δ ⊢ A
              h rewrite sym (++-assoc (B ∷ Γ) (B ∷ Γ) Δ)
                      = f
\end{code}
</div>
<div class="foldable">
\begin{code}
    s⁺′ : ∀ {A} → ∀ Γ Σ → ∀ {Π} → NJ (Γ ++ Σ) ++ Π ⊢ A
                → NJ (Γ ++ Π) ++ Σ ⊢ A
    s⁺′ {A} Γ Σ {Π} f
      = subst (λ Σ → NJ (Γ ++ Π) ++ Σ ⊢ A)      (++-identityʳ Σ)
      $ p⁺′ Γ Σ Π
      $ subst (λ Π → NJ (Γ ++ Σ) ++ Π ⊢ A) (sym (++-identityʳ Π))
      $ f
\end{code}
</div>

\begin{code}
    ax′ : ∀ {A Γ} → A ∈ Γ → NJ Γ ⊢ A
    ax′ {A} {B ∷ Γ} (here px) rewrite px = s⁺′ [] Γ (w⁺′ Γ ax)
    ax′ {A} {B ∷ Γ} (there x)            = w (ax′ x)
\end{code}

It turns out to be very useful to define two helper functions which introduce and eliminate the empty context to the right. This is because <span class="Agda Spec"><a class="Bound">Γ</a> <a href="https://agda.github.io/agda-stdlib/Data.List.Base.html#895" class="Function Operator" target="_blank">++</a> <a href="https://agda.github.io/agda-stdlib/Agda.Builtin.List.html#89" class="InductiveConstructor" target="_blank">[]</a></span> doesn't automatically reduce. Therefore, any proof in which the empty context occurs to the right would involve rewriting by <a class="Agda Spec Function">++&#8209;identityʳ</a>.

\begin{code}
    ∅i : ∀ {A Γ} → NJ Γ ⊢ A → NJ Γ ++ [] ⊢ A
    ∅i {A} {Γ} f rewrite ++-identityʳ Γ = f
    ∅e : ∀ {A Γ} → NJ Γ ++ [] ⊢ A → NJ Γ ⊢ A
    ∅e {A} {Γ} f rewrite ++-identityʳ Γ = f
\end{code}



### Implicit and Explicit Structural Rules

\begin{code}
  module NJ⇔ND where

    ⟹ : ∀ {S} → NJ S → ND S
    ⟹  ax         = ax₀
    ⟹ (⇒i f  )    = ⇒i (⟹ f)
    ⟹ (⇒e {Γ = Γ} f g)    = ⇒e (inl (⟹ f)) (inr (⟹ g))
      where
        inl : ∀ {A Δ} → ND Γ ⊢ A → ND Γ ++ Δ ⊢ A
        inl {Δ = Δ} f = ND.s⁺′ [] Δ (ND.w⁺′ Δ f)
        inr : ∀ {A Δ} → ND Δ ⊢ A → ND Γ ++ Δ ⊢ A
        inr f = ND.w⁺′ Γ f

    ⟹ (w    f)    = ND.w′   (⟹ f)
    ⟹ (c    f)    = ND.c′   (⟹ f)
    ⟹ (p  Γ f)    = ND.p′ Γ (⟹ f)

    ⟸ : ∀ {S} → ND S → NJ S
    ⟸ (ax  x)     = NJ.ax′ x
    ⟸ (⇒i  f)     = ⇒i  (⟸ f)
    ⟸ (⇒e  {Γ = Γ} f g)   = NJ.∅e (NJ.c⁺′ Γ (NJ.∅i (⇒e (⟸ f) (⟸ g))))
\end{code}


### Sequent Calculus with Explicit Structural Rules

$$
  \begin{array}{c}
  \frac{}{A \vdash A}{\small ax}
  \quad
  \frac{\Gamma \vdash A \quad A , \Delta \vdash B}{\Gamma, \Delta \vdash B}{\small cut}
  \\
  \\
  \frac{\Gamma \vdash A \quad B , \Delta \vdash C}{A \Rightarrow  B , \Gamma, \Delta \vdash C}{\small{\Rightarrow}\!l}
  \quad
  \frac{A , \Gamma \vdash B}{\Gamma \vdash A \Rightarrow B}{\small{\Rightarrow}\!r}
  \\
  \\
  \frac{\Gamma \vdash B}{A , \Gamma \vdash B}{\small w}
  \quad
  \frac{A , A , \Gamma \vdash B}{A , \Gamma \vdash B}{\small c}
  \quad
  \frac{\Gamma , A , B , \Delta \vdash B}{\Gamma , B , A , \Delta \vdash B}{\small p}
  \end{array}
$$

\begin{code}
  infix 3 LJ_

  data LJ_ : Sequent → Set where
    ax  : ∀ {A        } → LJ A ∷ [] ⊢ A
    cut : ∀ {A B   Γ Δ} → LJ Γ ⊢ A → LJ A ∷ Δ ⊢ B → LJ Γ ++ Δ ⊢ B
    ⇒l  : ∀ {A B C Γ Δ} → LJ Γ ⊢ A → LJ B ∷ Δ ⊢ C → LJ A ⇒ B ∷ Γ ++ Δ ⊢ C
    ⇒r  : ∀ {A B   Γ  } → LJ A ∷ Γ ⊢ B → LJ Γ ⊢ A ⇒ B
    w   : ∀ {A B   Γ  } → LJ Γ ⊢ B → LJ A ∷ Γ ⊢ B
    c   : ∀ {A B   Γ  } → LJ A ∷ A ∷ Γ ⊢ B → LJ A ∷ Γ ⊢ B
    p   : ∀ {A B C} → ∀ Γ → ∀ {Δ} → LJ Γ ++ A ∷ B ∷ Δ ⊢ C → LJ Γ ++ B ∷ A ∷ Δ ⊢ C
\end{code}

<div class="hidden">
\begin{code}
  module LJ where
\end{code}
</div>


\begin{code}
    ∅i : ∀ {A Γ} → LJ Γ ⊢ A → LJ Γ ++ [] ⊢ A
    ∅i {A} {Γ} f rewrite ++-identityʳ Γ = f
    ∅e : ∀ {A Γ} → LJ Γ ++ [] ⊢ A → LJ Γ ⊢ A
    ∅e {A} {Γ} f rewrite ++-identityʳ Γ = f
\end{code}

\begin{code}
  module LJ⇔NJ where

    ⟹ : ∀ {S} → LJ S → NJ S
    ⟹  ax       = ax
    ⟹ (cut {Δ = Δ} f g) = NJ.s⁺′ [] Δ (⇒e (⇒i (⟹ g)) (⟹ f))
    ⟹ (⇒l  {Δ = Δ} f g) = NJ.s⁺′ [] Δ (⇒e (⇒i (⟹ g)) (⇒e ax (⟹ f)))
    ⟹ (⇒r  f)   = ⇒i  (⟹ f)
    ⟹ (w   f)   = w   (⟹ f)
    ⟹ (c   f)   = c   (⟹ f)
    ⟹ (p Γ f)   = p Γ (⟹ f)

    ⟸ : ∀ {S} → NJ S → LJ S
    ⟸  ax       = ax
    ⟸ (⇒i  f)   = ⇒r  (⟸ f)
    ⟸ (⇒e  f g) = cut (⟸ f) (LJ.∅e (⇒l (⟸ g) ax))
    ⟸ (w   f)   = w   (⟸ f)
    ⟸ (c   f)   = c   (⟸ f)
    ⟸ (p Γ f)   = p Γ (⟸ f)
\end{code}

\begin{code}
  module LJ⇔SC where

    ⟹ : ∀ {S} → LJ S → SC S
    ⟹ f = ND⇔SC.⟹ (NJ⇔ND.⟹ (LJ⇔NJ.⟹ f))

    ⟸ : ∀ {S} → SC S → LJ S
    ⟸ f = LJ⇔NJ.⟸ (NJ⇔ND.⟸ (ND⇔SC.⟸ f))
\end{code}


$$
  \begin{array}{ccccc}
  NJ           & \leftrightarrow & ND           & \rightarrow & Agda \\
  \\
  \updownarrow &                 & \updownarrow &             &      \\
  \\
  LJ           & \leftrightarrow & SC           &             &
  \end{array}
$$

---

[^minproplog]: Or, alternatively, as axiomatisations of minimal propositional logic.

[^admit]: As used here, *admit* or *admissible* is a technical term, usually contrasted with *derivable*. Derivable rules are rules that we can construct directly, without inspecting the proofs that we're given as arguments. On the other hand, admissible means that we can define these rules, but that we have to inspect and rewrite the proofs we're given.

<div class="hidden">
\begin{code}
-- -}
-- -}
-- -}
-- -}
-- -}
\end{code}
</div>