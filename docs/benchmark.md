# IParty

## Benchmark

This is the result of `script/benchmark.rb` on my M1.

```
RSS-before[uncached]: 28.98 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
            uncached   145.000 i/100ms
Calculating -------------------------------------
            uncached      1.454k (± 2.1%) i/s  (687.88 μs/i) -     87.290k in  60.075809s
RSS-after[uncached]: 49.45 MB


RSS-before[singletons]: 30.17 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
          singletons   163.000 i/100ms
Calculating -------------------------------------
          singletons      1.633k (± 1.3%) i/s  (612.35 μs/i) -     98.126k in  60.097790s
RSS-after[singletons]: 31.28 MB


RSS-before[eager_load]: 30.62 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
          eager_load   449.000 i/100ms
Calculating -------------------------------------
          eager_load      4.566k (± 1.3%) i/s  (219.02 μs/i) -    274.339k in  60.095499s
RSS-after[eager_load]: 114.52 MB
```

### Personal conclusion

I personally would rather not have mmdb-freshness tied to app-boot.
Hence I personally use no singletons unless I heavily use IParty in which case I would use the
CurrentAttributes way of caching non-eagerly-loaded instances per request with an additional per-request ipcache.
See documentation for more details.
