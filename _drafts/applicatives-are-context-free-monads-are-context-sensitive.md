---
title        : "Applicatives are Context Free"
date         : 2019-07-21 12:00:00
tags         : [formal language theory, haskell, agda]
---

Over the past few days, there's a question that came up repeatedly, first [on Twitter][beka], then after [a talk by Simon Marlow on Selective Functors][coplas]. That question?

> What is the expressiveness of applicative and monadic parser combinators?

Folklore tells us that applicative parsers parse context-free grammars, and monadic parsers parse, well, at very least context-sensitive grammars. However, I've not been able to find a formal proof of the matter, or much writing on the topic at all!


### Narrowing Down the Question

In this blog post, I'm gonna talk about applicative parser combinators, because honestly, I wrote too many words, and I can't fit a discussion of monadic parsers in here as well... 

So, the terms "applicative" and "monadic parser combinators" aren't quite accurate. If we only had instances of the applicative or monadic type classes, we wouldn't be able to write parsers that parse anything beyond a single, set phrase. These terms are commonly understood to mean parser combinators with instances of the Applicative *and* Alternative type classes (or Monad *and* MonadPlus). These additional type classes let us choose between two alternatives, e.g., parse "apple" *or* "orange". (They're essentially the same type class; the only differences are the function names and the subclass constraint.)

<!-- TODO: add links to the definitions of Applicative, Alternative, etc. -->

Brent Yorgey has written about [a trick][yorgey] which allows you to parse any recursively enumerable language[^erratum] using applicative parsers, by using recursion to create a production rule for each word in the language, creating a (potentially) infinite grammar.
Brent argues that this means that this means parsers written using applicative parser combinators are way more expressive than context-free grammars.
Instead, I'd argue that Brent has misinterpreted the question. Brent isn't talking about applicative parser combinators. They're talking about applicative parser combinators *plus* the ability to use recursion in the metalanguage (i.e., Haskell) to construct infinite grammars. There are *tons* of ways to embed an arbitrary Haskell into a parser combinator. Many parser combinator libraries actually include the ability to turn `String -> Bool` functions into parsers *directly*, e.g. [`satisfy`][satisfy]. If we don't rule out such combinators, we can parse any recursively enumerable language, simply because Haskell can.

There's another problem with the question. Context-free grammars are an abstract grammar formalism. They describe languages, but they don't come equipped with any specific way to *parse*. Parser combinator libraries are *parser libraries*. They *are* a specific way to parse. However, there is no abstract notion of what parser combinators are; there are only concrete libraries. So while it makes sense to say that [Parsec] can parse "predictive LL[1] grammars," it doesn't make sense to say that parser combinators *in general* are context-free. It's not so much apples and oranges as it is thoughts of fruit and actual fruit.


### Thoughts of Apples, Thoughts of Parsers

To have any chance of meaningfully answering the question of expressivity, we'll have to come up with grammar formalism which captures what parser combinators *ideally* mean.

Following [the Wikipedia definition for context-free grammars][cfgformal], we define a parser combinator grammar as a 4-tuple $$G = (V, \Sigma, S, \bar{D})$$ where:

  - $$V$$ is a finite set; each element $$v \in V$$ is called a *nonterminal character* or syntactic category. Each variable defines a sub-language of the language defined by $$G$$. <br /> (In Haskell, $$V$$ is the set of Haskell names for the parsers.)
  - $$\Sigma$$ is a finite set, disjoint from $$V$$; each element $$c \in \Sigma$$ is called a *terminal* character. Terminals make up the actual content of the sentence or program. <br /> (In Haskell, $$\Sigma$$ is usually the set of values of the `Char` type.)
  - $$S$$ is the *start symbol*, used to represent the syntactic category for the whole sentence or program. It must be an element of $$V$$. <br /> (In Haskell, $$S$$ is one of the names in $$V$$.)
  - $$\bar{D}$$ is a function from nonterminals to parsers, written as a collection of (potentially recursive) definitions $$v = p$$. The syntax of parsers $$p$$ is as follows:

    $$
    \begin{array}{lrlrl}
    p & ::=  & \texttt{char}\;c
      & \mid & v
    \\& \mid & p_1 \mathbin{\texttt{<*>}} p_2
      & \mid & \texttt{succeed}
    \\& \mid & p_1 \mathbin{\texttt{<|>}} p_2
      & \mid & \texttt{fail}
    \end{array}
    $$
    
    Each nonterminal is defined with a number of arguments, and each call to a nonterminal should provide that number of arguments. The start symbol $$S$$ should be defined with no arguments.

    (In Haskell, $$\text{char}$$ corresponds to, e.g., Parsec's [`char`][char], $$\texttt{succeed}$$ and $$\texttt{<*>}$$ correspond to the [`pure`][pure] and [`(<*>)`][ap] functions from Applicative[^sucarg], and $$\texttt{fail}$$ and $$\texttt{<}\vert\texttt{>}$$ correspond to the [`empty`][empty] and [`(<|>)`][alt] functions from Alternative.)

For a grammar $$G = (V, \Sigma, S, \bar{D})$$ we inductively define a binary relation from $$V$$ to $$\Sigma^*$$, which we write as $$v \mathbin{\textit{accepts}} w$$:

$$
\begin{array}{c}
% no premises
\\ \hline
\texttt{char}\;c \mathbin{\text{accepts}} c
\end{array}\;{\tiny(\texttt{R-char})}
\quad
\begin{array}{c}
\bar{D}(v) \mathbin{accepts} w
\\ \hline
v \mathbin{\text{accepts}} w
\end{array}\;{\tiny(\texttt{R-call})}
$$

$$
\begin{array}{c}
% no premises
\\ \hline
\texttt{succeed} \mathbin{\text{accepts}} \epsilon
\end{array}\;{\tiny(\texttt{R-succeed})}
\quad
\text{(no rule for \texttt{fail})}
$$

$$
\begin{array}{c}
p_1 \mathbin{\text{accepts}} w_1
\qquad
p_2 \mathbin{\text{accepts}} w_2
\\ \hline
(p_1\mathbin{\texttt{<*>}}p_2) \mathbin{\text{accepts}} w_1w_2
\end{array}\;{\tiny(\texttt{R-<*>})}
$$

$$
\begin{array}{c}
p_1 \mathbin{\text{accepts}} w
\\ \hline
(p_1\mathbin{\texttt{<|>}}p_2) \mathbin{\text{accepts}} w
\end{array}\;{\tiny(\texttt{R-<|>}_1)}
\quad
\begin{array}{c}
p_2 \mathbin{\text{accepts}} w
\\ \hline
(p_1\mathbin{\texttt{<|>}}p_2) \mathbin{\text{accepts}} w
\end{array}\;{\tiny(\texttt{R-<|>}_2)}
$$

You can read these from bottom to top: the statement below the line is true if all statements above the line are true. Keeping this in mind, we can read these rules as follows:

  - The parser $$\texttt{char}\;c$$ accepts *only* the symbol $$c$$.
  - To find out what the parser $$v$$ accepts, we look up the definition of $$v$$.
  - The parser $$\texttt{succeed}$$ always succeeds, and accepts the empty string.
  - The parser $$\texttt{fail}$$ always fails, so there's no rule.
  - The parser $$p_1 \mathbin{\texttt{<*>}} p_2$$ accepts a word from the language $$p_1$$ followed by a word from the language $$p_2$$.
  - The parser $$p_1 \mathbin{\texttt{<}\vert\texttt{>}} p_2$$ accepts a word either from the language $$p_1$$ or from the language $$p_2$$.

The language of a grammar $$G = (V,\Sigma,S,\bar{D})$$ is the set

$$
\mathcal{L}(G) =
\{ w \in \Sigma^\star \mid S \mathbin{\textit{accepts}} w \}
$$


### We Need Examples!

First off, a pretty theoretic one, a quintessential context-free language, the *counting language* $$a^n b^n$$, i.e., any word with $$n$$ $$a$$'s followed by $$n$$ $$b$$'s. It's quintessentially context free 'cuz you need *at least* a context-free grammar formalism to generate it; regular grammars can't do it! We can generate this language from the following grammar:

$$
\begin{array}{rl}
S \quad = 
& \texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright}
\\
\mathbin{\texttt{<|>}} 
& \texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} S \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright}
\end{array}
$$

Let's see. Do we have $$S \mathbin{\textit{accepts}} aabb$$?

$$
\begin{array}{c}
\begin{array}{c}
\begin{array}{c}
\begin{array}{c}
\\ \hline
\texttt{char}\;\lq{a}\text{\textquoteright}
\mathbin{\textit{accepts}} a
\end{array}
\quad
\begin{array}{c}
\begin{array}{c}
\vdots
\\
S
\mathbin{\textit{accepts}} ab
\end{array}
\quad
\begin{array}{c}
\\ \hline
\texttt{char}\;\lq{b}\text{\textquoteright}
\mathbin{\textit{accepts}} b
\end{array}
\\ \hline
(
S \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright}
)
\mathbin{\textit{accepts}} abb
\end{array}
\\ \hline
(
\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} S \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright}
)
\mathbin{\textit{accepts}} aabb
\end{array}
\\ \hline
(
(\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright})
\mathbin{\texttt{<|>}} 
(\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} S \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright})
)
\mathbin{\textit{accepts}} aabb
\end{array}
\\ \hline
S \mathbin{\textit{accepts}} aabb
\end{array}
$$

Okay, so $$S \mathbin{\textit{accepts}} aabb$$ if $$S \mathbin{\textit{accepts}} aabb$$! Does it?

$$
\begin{array}{c}
\begin{array}{c}
\begin{array}{c}
\begin{array}{c}
\\ \hline
\texttt{char}\;\lq{a}\text{\textquoteright}
\mathbin{\textit{accepts}} a
\end{array}
\quad
\begin{array}{c}
\\ \hline
\texttt{char}\;\lq{b}\text{\textquoteright}
\mathbin{\textit{accepts}} b
\end{array}
\\ \hline
(
\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright}
)
\mathbin{\textit{accepts}} ab
\end{array}
\\ \hline
(
(\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright})
\mathbin{\texttt{<|>}} 
(\texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<*>}} S \mathbin{\texttt{<*>}} \texttt{char}\;\lq{b}\text{\textquoteright})
)
\mathbin{\textit{accepts}} ab
\end{array}
\\ \hline
S \mathbin{\textit{accepts}} ab
\end{array}
$$

It does!

Second example! Let's do something a little bit more practical. A grammar for the tiniest functional programming language: the untyped lambda calculus. We're not going to bother with spacing for this grammar, just to keep things simple.

$$
\begin{array}{lrl}
\text{Letter} & = & \texttt{char}\;\lq{a}\text{\textquoteright} \mathbin{\texttt{<|>}} \dots \mathbin{\texttt{<|>}} \texttt{char}\;\lq{z}\text{\textquoteright}
\\
\text{Ident}  & = & \text{Letter} \mathbin{\texttt{<|>}} (\text{Letter} \mathbin{\texttt{<*>}} \text{Ident})
\\
\text{Expr}   & = & \text{Ident}
\\
& \mathbin{\texttt{<|>}} & 
\texttt{char}\;\lq(\text{\textquoteright}
\mathbin{\texttt{<*>}}
\texttt{char}\;\lq\lambda\text{\textquoteright} 
\mathbin{\texttt{<*>}} 
\text{Ident} 
\mathbin{\texttt{<*>}} 
\texttt{char}\;\lq.\text{\textquoteright} 
\mathbin{\texttt{<*>}} 
\text{Expr}
\mathbin{\texttt{<*>}} 
\texttt{char}\;\lq)\text{\textquoteright}
\\
& \mathbin{\texttt{<|>}} & 
\texttt{char}\;\lq(\text{\textquoteright}
\mathbin{\texttt{<*>}}
\text{Expr}
\mathbin{\texttt{<*>}}
\texttt{char}\;\lq\;\text{\textquoteright}
\mathbin{\texttt{<*>}}
\text{Expr}
\mathbin{\texttt{<*>}}
\texttt{char}\;\lq)\text{\textquoteright}
\end{array}
$$

Okay, so that isn't super neat, and inserts *a lot* of superfluous parentheses, but it does the job. You can verify for yourself that this grammar parses, e.g., the non-terminating term $$\omega$$, $$((\lambda{x}.(x\;x))\;(\lambda{x}.(x\;x)))$$.


### When is a Context Free?

Great! So we know what a parser combinator grammar is now! Let's prove that they're context free! I, uh, kinda need to explain what a context-free grammar is first, don't I? Like, I'm basically gonna copy the definition from [Wikipedia][cfgformal] here.

We define a context-free grammar as a 4-tuple $$G = (V, \Sigma, S, R)$$ where:

  - $$V$$ is a finite set; each element $$v \in V$$ is called a *nonterminal character* or syntactic category. Each variable defines a sub-language of the language defined by $$G$$.
  - $$\Sigma$$ is a finite set, disjoint from $$V$$; each element $$c \in \Sigma$$ is called a *terminal* character. Terminals make up the actual content of the sentence or program.
  - $$S$$ is the *start symbol*, used to represent the syntactic category for the whole sentence or program. It must be an element of $$V$$.
  
(So, exactly like above.)

  - $$R$$ is a finite relation from $$V$$ to $$(V \cup \Sigma)^*$$, where the asterisk represents the [Kleene star][kleene] operation. That means it's a relation from nonterminals to sequences of nonterminals and terminals. Elements of $$R$$ are called rewrite rules or *productions*. Productions are usually written with an arrow, e.g., for a nonterminal $$v \in V$$ and a sequence of nonterminals and nonterminals $$s \in (V \cup \Sigma)^*$$, we write $$v \rightarrow s$$.
  
For a grammar $$G = (V, \Sigma, S, R)$$, for $$s, t \in (V \cup \Sigma)^*$$, we define a binary relation, written as $$s \Rightarrow t$$, by which we mean that $$s$$ can be turned into $$t$$ by applying a *single* production:

$$
\begin{array}{c}
v \rightarrow s
\\ \hline
t_1 v t_2 \Rightarrow t_1 s t_2
\end{array}
$$

We then take the reflexive-transitive closure of this relation, i.e., we define a new binary relation, which is applies $$\Rightarrow$$ any number of times. We write this new relation as $$s \Rightarrow^* t$$:

$$
\begin{array}{c}
% no premises
\\ \hline
t \Rightarrow^* t
\end{array}
\quad
\begin{array}{c}
t_1 \Rightarrow t_2
\\ \hline
t_1 \Rightarrow^* t_2
\end{array}
\quad
\begin{array}{c}
t_1 \Rightarrow^* t_2 \quad t_2 \Rightarrow^* t_3
\\ \hline
t_1 \Rightarrow^* t_3
\end{array}
$$

The language of a grammar $$G = (V,\Sigma,S,R)$$ is the set

$$
\mathcal{L}(G) =
\{ w \in \Sigma^\star \mid S \Rightarrow^* w \}
$$


### Applicatives are Context Free

TODO: prove defunctionalisation in parser combinator grammars, reducing everything to nullary definitions

TODO: my definition for parser combinator grammars is first-order, to make it higher-order I'd have to allow arbitrary nonterminals to be passed in... does that actually make my life easier?

---

[^erratum]: Brent argues that the technique can be used to parse *context-sensitive* languages, but the technique can convert arbitrary functions of type `String -> Bool` to parsers, and hence can be used to parse any *recursively enumerable* language. This is pointed out in the comments.
[^sucarg]: I've removed the argument to `pure`, as we're only concerned with whether or not a parse succeeds, not what it returns

[techrep]: http://www.cs.uu.nl/research/techreps/repo/CS-2008/2008-044.pdf
[structamb]: https://en.wikipedia.org/wiki/Syntactic_ambiguity
[wadler]: https://dl.acm.org/citation.cfm?id=5288
[beka]: https://twitter.com/beka_valentine/status/1118924404040159232
[coplas]: https://di.ku.dk/english/event-calendar-2019/coplas-talk-simon-marlow-facebook/
[techrep]: http://www.cs.uu.nl/research/techreps/repo/CS-2008/2008-044.pdf
[wadler]: https://dl.acm.org/citation.cfm?id=5288
[yorgey]: https://byorgey.wordpress.com/2012/01/05/parsing-context-sensitive-languages-with-applicative/
[cfgparsing]: https://en.wikipedia.org/wiki/Context-free_grammar#Parsing
[parsec]: https://wiki.haskell.org/Parsec
[llparser]: https://en.wikipedia.org/wiki/LL_parser
[firstclass]: http://www.cs.uu.nl/research/techreps/repo/CS-2011/2011-032.pdf
[cfgformal]: https://en.wikipedia.org/wiki/Context-free_grammar#Formal_definitions
[satisfy]: http://hackage.haskell.org/package/parsec-3.1.13.0/docs/Text-Parsec-Char.html#v:satisfy
[char]: http://hackage.haskell.org/package/parsec-3.1.13.0/docs/Text-Parsec-Char.html#v:char
[ap]: http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Applicative.html#v:-60--42--62-
[pure]: http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Applicative.html#v:pure
[alt]: http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Applicative.html#v:-60--124--62-
[empty]: http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Applicative.html#v:empty
[kleene]: https://en.wikipedia.org/wiki/Kleene_star
