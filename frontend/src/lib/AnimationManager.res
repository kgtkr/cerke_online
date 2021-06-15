open Belt

type t = {registerAnimation: ((unit => unit) => unit) => unit}

// durationは呼び出しごとに変わらないことを想定している
let useAnimationValue = (x: 'a, ~duration: int, ~eq: Relude.Eq.eq<'a>, ~manager: t): 'a => {
  let prevX = React.useRef(x)
  let (renderX, setRenderX) = React.useState(() => x)
  React.useEffect1(() => {
    if !eq(x, prevX.current) {
      prevX.current = x
      manager.registerAnimation(end => {
        setRenderX(_ => x)
        let _ = Js.Global.setTimeout(() => {
          end()
        }, duration)
      })
    }
    None
  }, [x])

  renderX
}

let useAnimationManager = (~timeout=5000, ()): t => {
  let running = React.useRef(false)
  let queue = React.useRef(MutableQueue.make())
  let rec checkQueue = () => {
    if !running.current {
      let _ =
        queue.current
        ->MutableQueue.pop
        ->OptionExt.forEach(callback => {
          running.current = true
          let calledEnd = ref(false)
          let end = () => {
            if !calledEnd.contents {
              calledEnd := true
              running.current = false
              checkQueue()
            } else {
              Js.Console.warn("[AnimationManager]End has already been called or timed out")
            }
          }

          let _ = Js.Global.setTimeout(() => {
            if !calledEnd.contents {
              Js.Console.warn("[AnimationManager]Animation timed out")
              end()
            }
          }, timeout)

          callback(end)
        })
    }
    ()
  }
  let registerAnimation = React.useCallback0(callback => {
    queue.current->MutableQueue.add(callback)
    checkQueue()
  })

  {registerAnimation: registerAnimation}
}
