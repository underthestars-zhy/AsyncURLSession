# AsyncURLSession

Apple brought us a very shiny feature `async`. And `URLSession` supported it at once. But you can't use `downloadTask` with async. So this package can help you deal with this kind of problem.

## Without Progress

```swift
let (url, response) = try await AsyncURLSession.shared.url(from: .init(string: "https://filesamples.com/samples/document/txt/sample1.txt")!)
```

In this case `AsyncURLSession` will provide you a system url which is the downloaded file path.

## With Progress

```swift
let (progress, response) = try await AsyncURLSession.shared.download(from: .init(string: "https://filesamples.com/samples/document/txt/sample1.txt")!, location: url)
let all = response.expectedContentLength

for try await current in progress {
    let progress = Double(current) / Double(all)

    print(Int(progress * 100), "%")
}
```

In this case, you need to provide a url where you file will be donwloaded to.

## Others

1. Both support `URL` and `URLRequest`
2. You can create your custom `AsyncURLSession`
3. Can use on `Linux` (not be tested, but I suppose to)
