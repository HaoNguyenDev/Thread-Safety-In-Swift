import Foundation

//MARK: -(Thread-Safe by Default " static let ")
/* Swift ensures that static variables are initialized in a thread-safe manner using a "one-time initialization" mechanism. Here's the simple and recommended way:
 
 Why thread-safe? Swift uses dispatch_once (or equivalent) to ensure that initialization of a static let shared only happens once, even if multiple threads try to access it at the same time.

 Note: This only ensures thread-safety for initializing a Singleton. If a Singleton has mutable properties (vars), you need to add your own protection.
 */

class MySingleton {
    @MainActor static let shared = MySingleton()
    private init() {}
}

//MARK: - (Thread-Safe by DispatchQueue)
/* If your Singleton has mutable properties or needs to perform non-thread-safe operations, you can use DispatchQueue to synchronize access, by using serial queues */
//MARK: Concurrent queues

class MySingleton_ConcurrentQueue {
    @MainActor static let shared = MySingleton_ConcurrentQueue()
    
    private let queue = DispatchQueue(label: "com.example.singleton", attributes: .concurrent)
    private var _data: String = ""
    
    var data: String {
        get {
            return queue.sync { _data }
        }
        set {
            queue.async(flags: .barrier) { self._data = newValue }
        }
    }
    
    /*
     get { sync }
     set { async }
     
     sync is used for reads to ensure immediate return of the value.
     async can be used for writes to avoid blocking the calling thread.
     
     In real world applications, writing data often does not need to return results immediately (like a getter). Using async helps to reduce unnecessary waiting time.
     */
    
    private init() {}
}

class NSLock_Singleton {
    @MainActor static let shared = NSLock_Singleton()
    
    private let lock = NSLock()
    private var _data: String = ""
    
    var data: String {
        get {
            lock.lock()
            defer { lock.unlock()}
            return _data
        }
        set {
            lock.lock()
            defer { lock.unlock()}
            _data = newValue
        }
    }
    
    private init() {}
}

//MARK: Actor with Swift Concurrency
/* Actors automatically manage synchronization, ensuring that only one task can access the actor's state at a time. This is the most modern and secure way if you use Swift Concurrency. */

actor Actor_Singleton {
    static let shared = Actor_Singleton()
    
    private var data: String = ""
    
    func setData(_ value: String) {
        data = value
    }
    
    func getData() -> String {
        return data
    }
    
    private init() {}
}

Task {
    let singleton = Actor_Singleton.shared
    await singleton.setData("Hello")
    let data = await singleton.getData()
    print(data) // "Hello"
}

//MARK: - DispatchSemaphore

class DispatchSemaphore_Singleton {
    @MainActor static let shared = DispatchSemaphore_Singleton()
    
    private let semaphore = DispatchSemaphore(value: 1)
    private var _data: String = ""
    
    var data: String {
        get {
            semaphore.wait()
            let value = _data
            defer { semaphore.signal() }
            return value
        }
        
        set {
            semaphore.wait()
            _data = newValue
            do { semaphore.signal() }
        }
    }
    
    private init() {}
}
