<?php

namespace LaundryPro\Api\Core;

/**
 * EventBus
 * 
 * A lightweight, synchronous, in-process event bus for decoupling cross-service logic.
 * E.g., Order created -> trigger notification logic without hardcoding dependencies.
 */
class EventBus
{
    private array $listeners = [];

    /**
     * Subscribe to an event.
     * 
     * @param string $eventName
     * @param callable $callback
     */
    public function subscribe(string $eventName, callable $callback): void
    {
        if (!isset($this->listeners[$eventName])) {
            $this->listeners[$eventName] = [];
        }
        $this->listeners[$eventName][] = $callback;
    }

    /**
     * Publish an event synchronously to all registered listeners.
     * 
     * @param string $eventName
     * @param mixed $payload
     */
    public function publish(string $eventName, $payload = null): void
    {
        if (!isset($this->listeners[$eventName])) {
            return;
        }

        foreach ($this->listeners[$eventName] as $listener) {
            call_user_func($listener, $payload);
        }
    }

    /**
     * Clear all listeners for testing or reset purposes.
     */
    public function clear(): void
    {
        $this->listeners = [];
    }
}
