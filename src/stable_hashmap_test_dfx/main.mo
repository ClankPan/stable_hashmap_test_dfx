
// import MyHashMap "./MyHashMap";

import Prim "mo:⛔";
import P "mo:base/Prelude";
import A "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import AssocList "mo:base/AssocList";


import Text "mo:base/Text";



actor {


    public func addNFT(name : Text, value : Nat) : async Text {
        put(name, value);
        return name;
    };



    // key-val list type
     type KVs<K, V> = AssocList.AssocList<K, V>;

    type K = Text;
    type V = Nat;

    let initCapacity : Nat = 1;
    let keyEq : (K, K) -> Bool = Text.equal;
    let keyHash : K -> Hash.Hash = Text.hash;

    //　ここをstableに変更 
    // here added stable
    stable var table : [var KVs<K, V>] = [var];
    stable var _count : Nat = 0;

    /// Returns the number of entries in this HashMap.
    public func size() : async Nat { _count};

    //  Deletes the entry with the key `k`. Doesn't do anything if the key doesn't
    /// exist.
    
    func delete(k : K) = ignore remove(k);

    /// Removes the entry with the key `k` and returns the associated value if it
    /// existed or `null` otherwise.
    func remove(k : K) : ?V {
      let m = table.size();
      if (m > 0) {
        let h = Prim.nat32ToNat(keyHash(k));
        let pos = h % m;
        let (kvs2, ov) = AssocList.replace<K, V>(table[pos], k, keyEq, null);
        table[pos] := kvs2;
        switch(ov){
          case null { };
          case _ { _count -= 1; }
        };
        ov
      } else {
        null
      };
    };

    // Gets the entry with the key `k` and returns its associated value if it
    // existed or `null` otherwise.
    public func get(k : K) : async ?V {
      let h = Prim.nat32ToNat(keyHash(k));
      let m = table.size();
      let v = if (m > 0) {
        AssocList.find<K, V>(table[h % m], k, keyEq)
      } else {
        null
      };
    };

    // Insert the value `v` at key `k`. Overwrites an existing entry with key `k`
    func put(k : K, v : V) = ignore replace(k, v);

    // Insert the value `v` at key `k` and returns the previous value stored at
    // `k` or `null` if it didn't exist.
    func replace(k : K, v : V) : ?V {
      if (_count >= table.size()) {
        let size =
          if (_count == 0) {
            if (initCapacity > 0) {
              initCapacity
            } else {
              1
            }
          } else {
            table.size() * 2;
          };
        let table2 = A.init<KVs<K, V>>(size, null);
        for (i in table.keys()) {
          var kvs = table[i];
          label moveKeyVals : ()
          loop {
            switch kvs {
              case null { break moveKeyVals };
              case (?((k, v), kvsTail)) {
                let h = Prim.nat32ToNat(keyHash(k));
                let pos2 = h % table2.size();
                table2[pos2] := ?((k,v), table2[pos2]);
                kvs := kvsTail;
              };
            }
          };
        };
        table := table2;
      };
      let h = Prim.nat32ToNat(keyHash(k));
      let pos = h % table.size();
      let (kvs2, ov) = AssocList.replace<K, V>(table[pos], k, keyEq, ?v);
      table[pos] := kvs2;
      switch(ov){
        case null { _count += 1 };
        case _ {}
      };
      ov
    };

    /// An `Iter` over the keys.
    func keys() : Iter.Iter<K>
    { Iter.map(entries(), func (kv : (K, V)) : K { kv.0 }) };

    /// An `Iter` over the values.
    func vals() : Iter.Iter<V>
    { Iter.map(entries(), func (kv : (K, V)) : V { kv.1 }) };

    /// Returns an iterator over the key value pairs in this
    /// `HashMap`. Does _not_ modify the `HashMap`.
    func entries() : Iter.Iter<(K, V)> {
      if (table.size() == 0) {
        object { public func next() : ?(K, V) { null } }
      }
      else {
        object {
          var kvs = table[0];
          var nextTablePos = 1;
          public func next () : ?(K, V) {
            switch kvs {
              case (?(kv, kvs2)) {
                kvs := kvs2;
                ?kv
              };
              case null {
                if (nextTablePos < table.size()) {
                  kvs := table[nextTablePos];
                  nextTablePos += 1;
                  next()
                } else {
                  null
                }
              }
            }
          }
        }
      }
    };
    
};
