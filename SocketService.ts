import { io, Socket } from 'socket.io-client';

// Socket.io服务类型定义
export interface SocketServiceOptions {
  serverUrl: string;
}

export interface RoomUser {
  id: string;
  name: string;
  color: string;
}

export interface TextUpdateData {
  text: string;
  cursorPosition?: number;
}

export interface UserConnectedData {
  userId: string;
  userCount: number;
}

// Socket.io服务类
export class SocketService {
  private socket: Socket | null = null;
  private serverUrl: string;
  private currentRoomId: string | null = null;
  private eventHandlers: Map<string, Function[]> = new Map();
  private authToken: string = '';

  constructor(options: SocketServiceOptions) {
    this.serverUrl = options.serverUrl;
  }

  // 设置身份验证令牌
  public setAuthToken(token: string): void {
    this.authToken = token;
  }

  // 连接到Socket.io服务器
  public connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.socket = io(this.serverUrl, {
          auth: {
            token: this.authToken
          }
        });

        this.socket.on('connect', () => {
          console.log('已连接到WebSocket服务器');
          resolve();
        });

        this.socket.on('connect_error', (error) => {
          console.error('WebSocket连接错误:', error);
          reject(error);
        });

        // 设置基本事件监听器
        this.setupEventListeners();
      } catch (error) {
        console.error('WebSocket连接失败:', error);
        reject(error);
      }
    });
  }

  // 断开连接
  public disconnect(): void {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
      this.currentRoomId = null;
      console.log('已断开WebSocket连接');
    }
  }

  // 加入协作房间
  public joinRoom(roomId: string): void {
    if (!this.socket) {
      throw new Error('WebSocket未连接');
    }

    // 如果已经在房间中，先离开
    if (this.currentRoomId) {
      this.leaveRoom();
    }

    this.socket.emit('join-room', roomId);
    this.currentRoomId = roomId;
    console.log(`已加入房间: ${roomId}`);
  }

  // 离开当前房间
  public leaveRoom(): void {
    if (!this.socket || !this.currentRoomId) {
      return;
    }

    this.socket.emit('leave-room', this.currentRoomId);
    console.log(`已离开房间: ${this.currentRoomId}`);
    this.currentRoomId = null;
  }

  // 发送文本更新
  public sendTextUpdate(text: string, cursorPosition?: number): void {
    if (!this.socket || !this.currentRoomId) {
      throw new Error('WebSocket未连接或未加入房间');
    }

    this.socket.emit('text-update', {
      roomId: this.currentRoomId,
      text,
      cursorPosition
    });
  }
  
  // 发送自定义事件
  public emit(event: string, data: any): void {
    if (!this.socket) {
      throw new Error('WebSocket未连接');
    }
    
    this.socket.emit(event, data);
  }

  // 注册事件监听器
  public on(event: string, callback: Function): void {
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }

    this.eventHandlers.get(event)!.push(callback);

    // 如果已连接，则立即注册到socket
    if (this.socket) {
      this.socket.on(event, (...args) => callback(...args));
    }
  }

  // 移除事件监听器
  public off(event: string, callback?: Function): void {
    if (!callback) {
      // 移除所有该事件的监听器
      this.eventHandlers.delete(event);
      if (this.socket) {
        this.socket.off(event);
      }
    } else {
      // 移除特定的监听器
      const handlers = this.eventHandlers.get(event);
      if (handlers) {
        const index = handlers.indexOf(callback);
        if (index !== -1) {
          handlers.splice(index, 1);
        }
        if (handlers.length === 0) {
          this.eventHandlers.delete(event);
          if (this.socket) {
            this.socket.off(event);
          }
        }
      }
    }
  }

  // 获取socket ID
  public getSocketId(): string | null {
    return this.socket ? this.socket.id : null;
  }

  // 是否已连接
  public isConnected(): boolean {
    return this.socket !== null && this.socket.connected;
  }

  // 设置基本事件监听器
  private setupEventListeners(): void {
    if (!this.socket) return;

    // 为已注册的事件设置监听器
    this.eventHandlers.forEach((callbacks, event) => {
      callbacks.forEach(callback => {
        this.socket!.on(event, (...args) => callback(...args));
      });
    });

    // 断开连接事件
    this.socket.on('disconnect', (reason) => {
      console.log(`WebSocket断开连接: ${reason}`);
    });
  }
}

// 创建单例实例
let instance: SocketService | null = null;

export const createSocketService = (options: SocketServiceOptions): SocketService => {
  if (!instance) {
    instance = new SocketService(options);
  }
  return instance;
};

export const getSocketService = (): SocketService => {
  if (!instance) {
    throw new Error('SocketService未初始化，请先调用createSocketService');
  }
  return instance;
}; 