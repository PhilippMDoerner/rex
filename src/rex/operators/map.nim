import ./operatorTypes
import std/[importutils]

proc mapSubscribe[SOURCE, RESULT](
  parent: Observable[SOURCE], 
  observer: Observer[RESULT],
  mapper: proc(value: SOURCE): RESULT {.closure.}
) = 
  proc onParentNext(value: SOURCE) =
    rerouteError(observer):
      let newValue = mapper(value)
      observer.next(newValue)
    
  let parentObserver = newForwardingObserver(observer, onParentNext)
  parent.subscribe(parentObserver)

proc map*[SOURCE, RESULT](
  parent: Observable[SOURCE],
  mapper: proc(value: SOURCE): RESULT {.closure.}
): Observable[RESULT] =
  privateAccess(Observable)
  let mapObservable = Observable[RESULT](
    completed: parent.completed,
    observers: @[],
  )
  
  mapObservable.completeProc = proc() =
    completeOperatorObservable(mapObservable)
  
  mapObservable.subscribeProc = proc(observer: Observer[RESULT]) =
    mapSubscribe(parent, observer, mapper)
    
  return mapObservable