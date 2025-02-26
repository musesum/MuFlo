/// below is an exploration of a command line interface, which is not imlemented.
/// most of Flo features have been, including `˚˚`, `<:>`, and `^`
/// but, runtime manipuation of graph has not. Same goes for quasi-bash commands.
///
///  Futuremore, the super-connected section with distributed closures and
///  activation iterations is rather aspiration, and subject to conceptual thrash.

/// `√ ` is a command line prompt. So, for the next three lines declare `a,b,c`

√ a 10       /// `a` stores `10`
a(10)

√ b %4       /// `b` filters input as `a modulo 4`
b( % 4)

√ c /2      /// `c`filters input as `a divide by 2`
c( / 2)

√ b <> a       /// `b` syncs with `a`
b( % 4) <> a      /// will filters input as `a modulo 4`

√ c <> a       /// `c` syncs with `a`
c( / 2) <> a      /// will filter input as `a divide by 2`

√ a!               /// `!`activates `a`, let's see what happens
a(10) => b( % 2 = 2)    /// `a` activates `b` as `10 % 4` assigned as `2`
a(10) => c( / 2 = 5)    /// and activates `c` as `10 / 2` assigned as `5`

√ b!               /// let's see what happens when we try to activate `b`
b(2) => a(2)        /// `b` activates `a`, which assigns a `2`, and
a(2) => c(/2=1)     /// `a` activates `c / 2` assigned as `1`

√ a=10, b=2, c=5   ///a let backtrack to the previous values
a(10), b(%4=2), c(/2=5)

/// notice that we only assigned values, and not
/// definitions or links. more on that later.

√ c!             /// now lets activate `c` and see what happens
c(5) => a(5)      /// `c` activate a which asigns a `5`
a(5) => b(%4=1)   /// `a` activate `b % 4` assigned as `1`

/// so order important, Flo will stop when it sees a place it
/// has already visited. So, no infinit loops.

/// But, we can still get into trouble, let's add an edge
√ b <> c           /// add another edge to  `c`
b(%4=1) <> (a,c)    /// now `b` is connected to both `a` and `c`

√ a!               /// activate `a`
a(5) => b(%4=1)     /// `a` activates `b % 4`, same as before
a(5) => c(/2=2.5)   /// `a` which activates `c`, but
b(1) ⁉️> c          /// `b`is blocked from activating `b`

/// so which value is assigned to `c`? depends on whether `a` or `b`
/// gets there first because it will block the other activation
/// so really the behavior cannot be predicted, it is `undefined`

/// we can resolve that that by making the edges go in only one direction
/// for example:

√ a -<> *      /// remove all the bidirectional edges to `a`
a, b, c         /// which cleared all the connects to `b` and `c`

√ a >> c       /// next, connect `a`'s output to `c`'s input
a >> b         /// so activations will only run in one direction

√ b >> c       ///. do the same for `b` to `c`
b >> c

√ c >> a       /// and the same for `c` to `a`
c >> a

√ a = 10        /// and assign 10 to a, activating `a`
a(10) => b(2)   /// whereupon, `a` activates `b` and
b(2)  => c(1)   /// `b` activates `c` -- consistently.

√ a?            /// anytime you want to show a name's contents
a(10) >> b      /// type `a`s name with a `?` to return the result

√ b?
b(%4 = 2) >> c     /// `b` shows both its and a's declaration

√ *            /// list everthing at this level
a, b, c

/// speaking levels, the `√` prompts means ws are at the root level
/// let's promate everything to a level deeper, called `d`


√ mv * d       /// the `mv` command is akin to bash's move command
d { a, b, c }   /// each name is both a file and a directory

√ cd d         /// so the `cd` is akin the change directory

√.d: *          /// resulting in a path prompt of `√.d`
a, b, c         /// with the `*` replacing `ls` for list

√.d: ..         /// `..` is shortcut for `cd ..`
√ *            /// and now list the root directory
d {a, b, c}     /// show the name tree one level deep
√ .d           ///
√ *

√ a.*?         /// we can still access via path names
a(10) <> (b,c)

√ mv * d       /// attempt something unwise
!! cannot move d to itself

√ mv * e       /// ok, let's add e
e { d { a, b, c } }

√ .e.d.c       /// we can move to a name like a directory
√.e.d.c: *      /// though there is nothing here
∅

√.e.d.c: cd \   /// so let's go  back to the root
√ e.d˚.        /// `˚.` wildcard finds all end names, like leaves on a tree
a, b, c

√ e.d˚. <> ..   /// lets connect the leaves to their parent `d`

e.d <> (e.d.a, e.d.b, e.d.c) /// which shows connections reative to root


√ ˚˚           /// `˚˚` finds all levels
e { d { a, b, c } }

√ ../˚˚??      /// show everthing all at once (EAAO)
√ {
    e {
        d <> (.a, .b, .c) {
            a(10) <> .. >> b << c
            b(%4=2) <> .. >> c << a
            c(/2=1) <> .. >> a << b
        }
    }
}
√ rm e        /// let's remove `e`
∅              /// oops, not what we want

√ cmd-z       /// to undo
e { d { a, b, c } }

/// each change graph creats a snapshot, all the way to the beginning
/// move forward with`shift-cmd-z` -- like any text editor

√ mv e.d .     /// move `√.e.d` to `√.d`
e d { a, b, c }

√ rm e         /// now we can remove `e`
d { a, b, c } }

√ ../˚˚??      /// show EAAO again
√ {
    d <> (.a, .b, .c) {
        a(10) <> .. >> b << c
        b(%4=2) <> .. >> c << a
        c(/2=1) <> .. >> a << b
    }
}
/// notice that links are relative and thus preserved

√ f : d        /// let's define f as d
{  d { a, b, c }
    f { a, b, c } }

√ ˚˚<>??       // EAAO again, to show that both
{               /// values and edges are preserved
    d <> (.a, .b, .c) {
        a(10)   <> .. >> b
        b(%4=2) <> .. >> c
        c(/2=1) <> .. >> a
    }
    f : d {
        a(10)   <> .. >> b
        b(%4=2) <> .. >> c
        c(/2=1) <> .. >> a
    }
}

√ ˚. /// here is a flat map of all the leaves
d.a, d.b, d.c, f.a, f.b, f.c

√ ˚˚--<>  /// lets get rid of the edges
{
    d {
        a(10)
        b(%4=2)
        c(/2=1)
    }
    f : d {
        a(10)
        b(%4=2)
        c(/2=1)
    }
}
√ ˚˚--() /// and for simplicy sake, let remove the values
{
    d     { a, b, c }
    f : d { a, b, c }
}

√ f <: d       /// and lets connect `d` to `f` by name
{               /// which allows `f` to shadow `d`
    d { a, b, c }
    f : d <: d {
        a <: d.a
        b <: d.b
        c <: d.c
    }
}
√ f <:> d      /// or we could synchronize between `f` and `d`
{               /// which allows `f` co-pilot  `d`
    d { a, b, c }
    f : d <:> d {
        a <:> d.a
        b <:> d.b
        c <:> d.c
    }
}
√ f˚˚ ^ copilot(0.25) /// add a `^ copilot` plugin `0.25` seconds
/// TBH, while there are animation plug-ins, there
/// is no such thing copilot plug-in.


√ f --<:>  \    /// or let's silently remove the co-pilot
√ f˚. <> d˚. ??   /// and superconnect all the leavea, instead
{
    d {
        a <> (f.a, f.b, f.c)
        b <> (f.a, f.b, f.c)
        c <> (f.a, f.b, f.c)
    }
    f {
        a <> (d.a, d.b, d.c)
        b <> (d.a, d.b, d.c)
        c <> (d.a, d.b, d.c)
    }
}
√ start <> d.*  \ /// connect a `start` node to `d.*`
√ finish <> f.* \ /// connect a `finish` node to `f.*`
√ start˚˚{ forward() } \ /// distribute a `forward()` closure from `start`
√ finish˚˚{ backward() } \ /// distribute a `backward()` closure from `finish`
√ (start,finish)! * 10000 /// run `forward` and `backward` passes `10000` times


/// current, there are no run loops in flo
/// the closest is in model.flo.h, used by the deepmuse app
/// where the `^ sky.main.anim` plug-in generates an easeinout animation of scalar values
