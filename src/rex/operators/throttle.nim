import ./operatorTypes
import std/[importutils, monotimes, times]

proc throttleSubscribe[T](
  observable: Observable[T], 
  observer: Observer[T],
  throttleProc: proc(value: T): Duration {.closure.}
): Subscription =
  var lastTriggerTime: MonoTime
  proc onParentNext(value: T) {.async.} =
      let delay = throttleProc(value)
      let now = getMonoTime()
      let elapsed = now - lastTriggerTime
      if elapsed >= delay:
        lastTriggerTime = now
        await observer.next(value)
  
  let parentObserver = newForwardingObserver(observer, onParentNext)
  let subscription = observable.subscribe(parentObserver)

  privateAccess(Subscription)
  return Subscription(
    unsubscribeProc: proc() = subscription.unsubscribe()
  )

proc throttle*[T](
  source: Observable[T], 
  throttleProc: proc(value: T): Duration {.closure.}
): Observable[T] =
  privateAccess(Observable)
  let throttleObservable = Observable[T](
    completed: source.completed,
    observers: @[]
  )
  
  throttleObservable.completeProc = proc() {.async.} =
    await completeOperatorObservable(throttleObservable)
  
  throttleObservable.subscribeProc = proc(observer: Observer[T]): Subscription =
    return throttleSubscribe(source, observer, throttleProc)
    
  return throttleObservable