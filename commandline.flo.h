/// `√: ` is a command line prompt. So, for the next three lines declare `a,b,c`

√: a: 10         /// `a` stores `10`
a(10)

√: b: % 4        /// `b` filters input as `a modulo 4`
b(%4)

√: c: / 2        /// `c`filters input as `a divide by 2`
c(/2)

√: b <> a
b <> a          /// `b` syncs with `a` and filters input as `a modulo 4`

√: c <> a
c <> a          /// `c` syncs with `a` and filters input as `a divide by 2`

√: a!           /// `!`activates `a`, let's see what happens
a(10) => b(2)   /// `a` activates `b` as `10 % 4` assigned as `2`
a(10) => c(5)   /// and activates `c` as `10 / 2` assigned as `5`

√: b!           /// let's see what happens when we try to activate `b`
b(2) => a(2)    /// `b` activates `a`, which assigns a `2`, and
a(2) => c(1)    /// `a` activates `c / 2` assigned as `1`

√: a:10, b:2, c:5   /// let backtrack to the previous values
a(10), b(2), c(5)

/// notice that we only assigned values, and not
/// definitions or links. more on that later.

√: c!             /// now lets activate `c` and see what happens
c(5) => a(5)      /// `c` activate a which asigns a `5`
a(5) => b(1)      /// `a` activate `b % 4` assigned as `1`

/// so order important, Flo will stop when it sees a place it
/// has already visited. So, no infinit loops.

/// But, we can still get into trouble, let's add and edge
√: b <> c       /// add another edge to  `c`
b <> (a,c)      /// now `b` is connected to both `a` and `c`

√: a!           /// activate a
a(5) => b(1)    /// `a` activates `b`
a(5) => c(2.5)  /// `a` which activates `c`, but
b(1) 🚫> c(0.5)  /// `b`is blocked from activating `b`

/// so which value is assigned to `c`? depends on whether `a` or `b`
/// gets there first because it will block the other activation
/// so really the behavior cannot be predicted, it is `undefined`

/// we can resolve that that by make the edge go in only one direction
/// for example:

√: a -<> *      /// remove all the bidirectional edges to `a`
a, b, c         /// which cleared all the connects to `b` and `c`

√: a >> c       /// next, connect `a`'s output to `c`'s input
a >> b          // so activations will only run in one direction

√: b >> c       ///. do the same for `b` to `c`
b >> c

√: c >> a       /// and the same for `c` to `a`
c >> a

√: a: 10        /// and assign 10 to a, activating `a`
a(10) => b(2)   /// whereupon, `a` activates `b` and
b(2)  => c(1)   /// `b` activates `c` -- consistently.

√: a            /// anytime you want to show everthing
a(10) <> (b,c)  /// type `a`s name and return the result

√: b
b(%4:2) >> c << a  // b shows both its and a's declaration

√: b


