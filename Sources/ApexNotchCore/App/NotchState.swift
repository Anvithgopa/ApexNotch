import SwiftUI

@MainActor
@propertyWrapper
public struct NotchState<Value>: DynamicProperty {
    @StateObject private var box: Box
    
    @MainActor
    private final class Box: ObservableObject {
        @Published var value: Value
        init(value: Value) { self.value = value }
    }
    
    public init(wrappedValue: Value) {
        _box = StateObject(wrappedValue: Box(value: wrappedValue))
    }
    
    public var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.value = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { [box] in box.value },
            set: { [box] in box.value = $0 }
        )
    }
}
