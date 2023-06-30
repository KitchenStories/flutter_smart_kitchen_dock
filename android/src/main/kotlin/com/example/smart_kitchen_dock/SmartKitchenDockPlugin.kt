package com.example.smart_kitchen_dock

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import java.io.IOException
import java.lang.ref.WeakReference
import java.nio.charset.StandardCharsets
import java.util.UUID

enum class Gesture {
  UP,
  DOWN,
  LEFT,
  RIGHT,
}

class BluetoothAdapterListener {
  private val protocolString = "com.smartkitchendock.protocol2"
  private var adapter = BluetoothAdapter.getDefaultAdapter()
  private val _events = MutableSharedFlow<Gesture>(replay = 1, onBufferOverflow = BufferOverflow.DROP_LATEST)
  val sharedFlow = _events.asSharedFlow()

  private var socket: BluetoothSocket? = null

  private var connectedAccesory: BluetoothDevice? = null
    get() {
//      val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
      val devices = adapter?.bondedDevices

      return devices?.firstOrNull {
        it.name.startsWith("Smart Kitchen Dock")
//          false
        }
      }

  fun generateUUIDFromProtocol(protocol: String): UUID {
    val protocolBytes = protocol.toByteArray(StandardCharsets.UTF_8)
    return UUID.nameUUIDFromBytes(protocolBytes)
  }
  fun resume(badapter: BluetoothAdapter, context : Context) {
    this.adapter = badapter
    val accessory = connectedAccesory ?: return
    var connectionRetries = 0
    var connected = false
    println("bondstate")
    println(accessory.bondState.toString())
    println("Address: ${accessory.address}")

    while (connected != true && connectionRetries < 3) {
      try {
        // UUID for Serial Port Profile (SPP)
        val UUID_SPP: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        print("uuid spp ${UUID_SPP}")

        socket = accessory.createRfcommSocketToServiceRecord(UUID_SPP)
        socket?.connect()

        connected = true
        println("Sockett connected ${socket?.isConnected}")
        // Do something with the socket
      } catch (e: IOException) {
        // Handle the exception
        connectionRetries = connectionRetries + 1
        println("SocketError")
        println(e)
        socket?.close()
        socket = null
      }
    }

    if (socket != null) {
      println("using socket")
      val listener = Thread {
        while (true) {
          try {
            var bytes = ByteArray(1024)
            socket!!.inputStream.read(bytes, 0, 1024)
            println("received")
            println(bytes)
            val gesture = decode(bytes)
//            _events.emit(gesture)
          } catch (e: IOException) {
          }

        }
      }
    }
//     */
  }

  fun decode(data: ByteArray): Gesture {
    // TODO decode byte array
    return Gesture.UP
  }

  fun pause() {
    socket?.close()
    socket = null
  }

  suspend fun sendTest() {
    println("SEnding TEST ${Gesture.DOWN}")
    _events.emit(Gesture.DOWN)
  }

  /*
  override fun onReceive(context: Context, intent: Intent) {
    val action = intent.action

    if (action == BluetoothAdapter.ACTION_STATE_CHANGED) {
      val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
    }
  }
  */
}


/** SmartKitchenDockPlugin */
class SmartKitchenDockPlugin: FlutterPlugin, EventChannel.StreamHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private var adapter = BluetoothAdapterListener()
  private lateinit var context: Context
  private lateinit var activity: Activity

  /*
   */
  override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
    println("on listen")
    println("with context ${context}")
    println("with activity ${activity}")
    println(adapter.sharedFlow)
//    val manager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
//    println(manager.adapter.bondedDevices)
//    adapter.resume(manager.adapter, context)
    this.eventSink = eventSink
//    adapter.sharedFlow.subscribe { value: Gesture ->
//      this.eventSink?.success("sharedflow ${value.name}")
//    }

    val subscribingScope = CoroutineScope(Dispatchers.Default)
    val evSink = WeakReference<EventChannel.EventSink>(eventSink)
    subscribingScope.launch() {
      adapter.sharedFlow.collect {
        val gesture = it
        activity.runOnUiThread() {
          evSink.get()?.success(mapOf(
            "type" to "gesture",
            "data" to gesture.name
          ))
        }


//      adapter.sharedFlow.collect {handler.post() {(evSink.get()?.success(it.name)) }
      }
    }
    subscribingScope.launch {
      adapter.sendTest()
    }
  }

  override fun onCancel(arguments: Any?) {
    println("on cancel")
    eventSink = null
    eventChannel = null
  }


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "smart_kitchen_dock")
//    channel.setMethodCallHandler(this)

    println("Engine attached")
    context = flutterPluginBinding.applicationContext
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "smart_kitchen_dock_events")
    eventChannel?.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }

  /*

   */
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
//    BluetoothManager bluetoothManager =(BluetoothManager) activity . getSystemService (Context.BLUETOOTH_SERVICE);
//    assert bluetoothManager != null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }
  override fun onDetachedFromActivityForConfigChanges() {
  }


}
